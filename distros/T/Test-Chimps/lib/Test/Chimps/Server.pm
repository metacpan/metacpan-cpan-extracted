package Test::Chimps::Server;

use warnings;
use strict;

use Test::Chimps::ReportCollection;
use Test::Chimps::Report;
use Test::Chimps::Server::Lister;

use Algorithm::TokenBucket;
use CGI::Carp   qw<fatalsToBrowser>;
use CGI;
use Digest::MD5 qw<md5_hex>;
use Fcntl       qw<:DEFAULT :flock>;
use File::Basename;
use File::Path;
use File::Spec;
use Jifty::DBI::Handle;
use Jifty::DBI::SchemaGenerator;
use Params::Validate qw<:all>;
use Storable    qw<store_fd fd_retrieve nfreeze thaw>;
use Test::TAP::HTMLMatrix;
use Test::TAP::Model::Visual;
use YAML::Syck;
use DateTime;

use constant PROTO_VERSION => 0.2;

=head1 NAME

Test::Chimps::Server - Accept smoke report uploads and display smoke reports

=head1 SYNOPSIS

This module simplifies the process of running a smoke server.  It
is meant to be used with Test::Chimps::Client.

    use Test::Chimps::Server;

    my $server = Test::Chimps::Server->new(base_dir => '/var/www/smokes');

    $server->handle_request;

=head1 METHODS

=head2 new ARGS

Creates a new Server object.  ARGS is a hash whose valid keys are:

=over 4

=item * base_dir

Mandatory.  Base directory where report data will be stored.

=item * bucket_file

Name of bucket database file (see L<Algorithm::Bucket>).  Defaults
to 'bucket.dat'.

=item * burst_rate

Burst upload rate allowed (see L<Algorithm::Bucket>).  Defaults to
5.

=item * database_dir

Directory under bsae_dir where the SQLite database will be stored.
Defaults to 'chimpsdb'.

=item * database_file

File under database_dir to use as the SQLite database.  Defaults to
'database'.

=item * list_template

Template filename under base_dir/template_dir to use for listing
smoke reports.  Defaults to 'list.tmpl'.

=item * lister

An instance of L<Test::Chimps::Server::Lister> to use to list smoke
reports.  You do not have to use this option unless you are
subclassing C<Lister>.

=item * max_rate

Maximum upload rate allowed (see L<Algorithm::Bucket>).  Defaults
to 1/30.

=item * max_size

Maximum size of HTTP POST that will be accepted.  Defaults to 3
MiB.

=item * max_reports_per_subcategory

Maximum number of smokes allowed per category.  Defaults to 5.

=item * template_dir

Directory under base_dir where html templates will be stored.
Defaults to 'templates'.

=item * variables_validation_spec

A hash reference of the form accepted by Params::Validate.  If
supplied, this will be used to validate the report variables
submitted to the server.

=back

=cut

use base qw/Class::Accessor/;

__PACKAGE__->mk_ro_accessors(
  qw/base_dir bucket_file max_rate max_size
    max_reports_per_subcategory database_dir database_file
    template_dir list_template lister
    variables_validation_spec handle/
);

sub new {
  my $class = shift;
  my $obj = bless {}, $class;
  $obj->_init(@_);
  return $obj;
}

sub _init {
  my $self = shift;
  my %args = validate_with(
    params => \@_,
    called => 'The Test::Chimps::Server constructor',
    spec   => {
      base_dir => {
        type     => SCALAR,
        optional => 0
      },
      bucket_file => {
        type     => SCALAR,
        default  => 'bucket.dat',
        optional => 1
      },
      burst_rate => {
        type      => SCALAR,
        optional  => 1,
        default   => 5,
        callbacks => {
          "greater than or equal to 0" => sub { $_[0] >= 0 }
        }
      },
      database_dir => {
        type     => SCALAR,
        optional => 1,
        default  => 'chimpsdb'
      },
      database_file => {
        type     => SCALAR,
        optional => 1,
        default  => 'database'
      },
      variables_validation_spec => {
        type     => HASHREF,
        optional => 1
      },
      list_template => {
        type     => SCALAR,
        optional => 1,
        default  => 'list.tmpl'
      },
      lister => {
        type     => SCALAR,
        isa      => 'Test::Chimps::Server::Lister',
        optional => 1
      },
      max_rate => {
        type      => SCALAR,
        default   => 1 / 30,
        optional  => 1,
        callbacks => {
          "greater than or equal to 0" => sub { $_[0] >= 0 }
        }
      },
      max_size => {
        type      => SCALAR,
        default   => 2**20 * 3.0,
        optional  => 1,
        callbacks => {
          "greater than or equal to 0" => sub { $_[0] >= 0 }
        }
      },
      max_reports_per_subcategory => {
        type      => SCALAR,
        default   => 5,
        optional  => 1,
        callbacks => {
          "greater than or equal to 0" => sub { $_[0] >= 0 }
        }
      },
      report_dir => {
        type     => SCALAR,
        default  => 'reports',
        optional => 1
      },
      template_dir => {
        type     => SCALAR,
        default  => 'templates',
        optional => 1
      }
    }
  );
  
  foreach my $key (keys %args) {
    $self->{$key} = $args{$key};
  }

  if (defined $self->variables_validation_spec) {
    foreach my $var (keys %{$self->variables_validation_spec}) {
      package Test::Chimps::Report::Schema;
      column($var, type(is('text')));
    }
  }

  my $dbdir = File::Spec->catdir($self->base_dir,
                                 $self->database_dir);
  if (! -e $dbdir) {
    mkpath($dbdir);
  }
  
  my $dbname = File::Spec->catfile($dbdir,
                                   $self->database_file);
  $self->{handle} = Jifty::DBI::Handle->new();

  # create the table if the db doesn't exist.  ripped out of
  # Jifty::Script::Schema because this stuff should be in
  # Jifty::DBI, but isn't
  if (! -e $dbname) {
    my $sg = Jifty::DBI::SchemaGenerator->new($self->handle);
    $sg->add_model(Test::Chimps::Report->new(handle => $self->handle));
  
    $self->handle->connect(driver => 'SQLite',
                           database => $dbname);
    # for non SQLite
#    $self->handle->simple_query('CREATE DATABASE database');
    $self->handle->simple_query($_) for $sg->create_table_sql_statements;
  } else {
    $self->handle->connect(driver => 'SQLite',
                           database => $dbname);
  }
}

=head2 handle_request

Handles a single request.  This function will either accept a
series of reports for upload or display report summaries.

=cut

sub handle_request {
  my $self = shift;

  my $cgi = CGI->new;
  if ($cgi->param("upload")) {
    $self->_process_upload($cgi);
  } elsif ($cgi->param("id")) {
    $self->_process_detail($cgi);
  } else {
    $self->_process_listing($cgi);
  }
}

sub _process_upload {
  my $self = shift;
  my $cgi = shift;

  print $cgi->header("text/plain");
  $self->_limit_rate($cgi);
  $self->_validate_params($cgi);  
  $self->_variables_validation_spec($cgi);
  $self->_add_report($cgi);

  print "ok";
}

sub _limit_rate {
  my $self = shift;
  my $cgi = shift;

  my $bucket_file = File::Spec->catfile($self->{base_dir},
                                        $self->{bucket_file});
  
  # Open the DB and lock it exclusively. See perldoc -q lock.
  sysopen my $fh, $bucket_file, O_RDWR|O_CREAT
    or die "Couldn't open \"$bucket_file\": $!\n";
  flock $fh, LOCK_EX
    or die "Couldn't flock \"$bucket_file\": $!\n";

  my $data   = eval { fd_retrieve $fh };
  $data    ||= [$self->{max_rate}, $self->{burst_rate}];
  my $bucket = Algorithm::TokenBucket->new(@$data);

  my $exit;
  unless($bucket->conform(1)) {
    print "Rate limiting -- please wait a bit and try again, thanks.";
    $exit++;
  }
  $bucket->count(1);

  seek     $fh, 0, 0  or die "Couldn't rewind \"$bucket_file\": $!\n";
  truncate $fh, 0     or die "Couldn't truncate \"$bucket_file\": $!\n";

  store_fd [$bucket->state] => $fh or
    croak "Couldn't serialize bucket to \"$bucket_file\": $!\n";

  exit if $exit;
}

sub _validate_params {
  my $self = shift;
  my $cgi = shift;
  
  if(! $cgi->param("version") ||
     $cgi->param("version") != PROTO_VERSION) {
    print "Protocol versions do not match!";
    exit;
  }

  if(! $cgi->param("model_structure")) {
    print "No model structure given!";
    exit;
  }

#  uncompress_smoke();
}

sub _variables_validation_spec {
  my $self = shift;
  my $cgi = shift;
  
  if (defined $self->{variables_validation_spec}) {
    my $report_variables = thaw($cgi->param('report_variables'));
    eval {
      validate(@{[%$report_variables]}, $self->{variables_validation_spec});
    };
    if (defined $@ && $@) {
      # XXX: doesn't dump subroutines because we're using YAML::Syck
      print "This server accepts specific report variables.  It's validation ",
        "string looks like this:\n", Dump($self->{variables_validation_spec}),
          "\nYour report variables look like this:\n", $cgi->param('report_variables');
      exit;
    }
  }
}

sub _add_report {
  my $self = shift;
  my $cgi = shift;

  my $params = {};

  $params->{timestamp} = DateTime->from_epoch(epoch => time);
  
  my $report_variables = thaw($cgi->param('report_variables'));
  foreach my $var (keys %{$report_variables}) {
    $params->{$var} = $report_variables->{$var};
  }
  
  my $model = Test::TAP::Model::Visual->new_with_struct(thaw($cgi->param('model_structure')));

  foreach my $var (
    qw/total_ok
    total_passed
    total_nok
    total_failed
    total_percentage
    total_ratio
    total_seen
    total_skipped
    total_todo
    total_unexpectedly_succeeded/
    )
  {

    $params->{$var} = $model->$var;
  }

  $params->{model_structure} = thaw($cgi->param('model_structure'));
  
  my $matrix = Test::TAP::HTMLMatrix->new($model,
                                          Dump(thaw($cgi->param('report_variables'))));
  $matrix->has_inline_css(1);
  $params->{report_html} = $matrix->detail_html;

  my $report = Test::Chimps::Report->new(handle => $self->handle);

  $report->create(%$params) or croak "Couldn't add report to database: $!\n";
}

sub _process_detail {
  my $self = shift;
  my $cgi = shift;

  print $cgi->header;
  
  my $id = $cgi->param("id");

  my $report = Test::Chimps::Report->new(handle => $self->handle);
  $report->load($id);
  
  print $report->report_html;
}

sub _process_listing {
  my $self = shift;
  my $cgi = shift;

  print $cgi->header();

  my $report_coll = Test::Chimps::ReportCollection->new(handle => $self->handle);
  $report_coll->unlimit;
  my @reports;
  while (my $report = $report_coll->next) {
    push @reports, $report;
  }

  my $lister;
  if (defined $self->lister) {
    $lister = $self->lister;
  } else {
    $lister = Test::Chimps::Server::Lister->new(
      list_template               => $self->list_template,
      max_reports_per_subcategory => $self->max_reports_per_subcategory
    );
  }
  
  $lister->output_list(File::Spec->catdir($self->{base_dir},
                                          $self->{template_dir}),
                       \@reports,
                       $cgi);
                                                   
}

=head1 AUTHOR

Zev Benjamin, C<< <zev at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-test-chimps at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Chimps>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Chimps

You can also look for information at:

=over 4

=item * Mailing list

Chimps has a mailman mailing list at
L<chimps@bestpractical.com>.  You can subscribe via the web
interface at
L<http://lists.bestpractical.com/cgi-bin/mailman/listinfo/chimps>.

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Chimps>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Chimps>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Chimps>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Chimps>

=back

=head1 ACKNOWLEDGEMENTS

Some code in this distribution is based on smokeserv-server.pl from
the Pugs distribution.

=head1 COPYRIGHT & LICENSE

Copyright 2006 Best Practical Solutions.
Portions copyright 2005-2006 the Pugs project.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
  
1;
