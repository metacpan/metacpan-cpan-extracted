package Prophet::Test::Editor;
{
  $Prophet::Test::Editor::VERSION = '0.751';
}
use strict;
use warnings;

use Prophet::Util;
use Params::Validate;
use File::Spec;


sub edit {
    my %args = @_;
    validate(
        @_,
        {
            edit_callback   => 1,
            verify_callback => 1,
            tmpl_files      => 1,
        }
    );

    my $option    = shift @ARGV;
    my $tmpl_file = $args{tmpl_files}->{$option};

    my @valid_template = Prophet::Util->slurp("t/data/$tmpl_file");
    chomp @valid_template;

    my $status_file = $ARGV[-2] =~ /status/ ? delete $ARGV[-2] : undef;

    # a bit of a hack to dermine whether the last arg is a filename
    my $replica_uuid =
      File::Spec->file_name_is_absolute( $ARGV[0] ) ? undef : shift @ARGV;
    my $ticket_uuid =
      File::Spec->file_name_is_absolute( $ARGV[0] ) ? undef : shift @ARGV;

    my @template = ();
    while (<>) {
        chomp( my $line = $_ );
        push @template, $line;

        $args{edit_callback}(
            option         => $option,
            template       => \@template,
            valid_template => \@valid_template,
            replica_uuid   => $replica_uuid,
            ticket_uuid    => $ticket_uuid,
        );
    }

    $args{verify_callback}(
        template       => \@template,
        valid_template => \@valid_template,
        status_file    => $status_file
    );
}


sub check_template_by_line {
    my @template       = @{ shift @_ };
    my @valid_template = @{ shift @_ };
    my $replica_uuid   = shift;
    my $ticket_uuid    = shift;
    my $errors         = shift;

    for my $valid_line (@valid_template) {
        my $line = shift @template;

        push @$errors, "got nothing, expected [$valid_line]"
          if !defined($line);

        push @$errors, "[$line] doesn't match [$valid_line]"
          if ( $valid_line =~ /^qr\// )
          ? $line !~ eval($valid_line)
          : $line eq $valid_line;
    }

    return !( @$errors == 0 );
}

1;

__END__

=pod

=head1 NAME

Prophet::Test::Editor

=head1 VERSION

version 0.751

=head1 FUNCTIONS

=head2 edit( tmpl_files => $tmpl_files, edit_callback => sub {}, verify_callback => sub {} )

Expects @ARGV to contain at least an option and a file to be edited. It can
also contain a replica uuid, a ticket uuid, and a status file. The last item
must always be the file to be edited. The others, if they appear, must be in
that order after the option. The status file must contain the string 'status'
in its filename.

edit_callback is called on each line of the file being edited. It should make
any edits to the lines it receives and then print what it wants to be saved to
the file.

verify_callback is called after editing is done. If you need to write whether
the template was correct to a status file, for example, this should be done
here.

=head2 check_template_by_line($template, $valid_template, $errors)

$template is a reference to an array containing the template to check, split
into lines. $valid_template is the same for the template to check against.
Lines in these arrays should not have trailing newlines. $errors is a reference
to an array where error messages will be stored.

Lines in $valid_template should consist of either plain strings, or strings
beginning with 'qr/' (to delimit a regexp object).

Returns true if the templates match and false otherwise.

=head1 AUTHORS

=over 4

=item *

Jesse Vincent <jesse@bestpractical.com>

=item *

Chia-Liang Kao <clkao@bestpractical.com>

=item *

Christine Spang <christine@spang.cc>

=back

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2009 by Best Practical Solutions.

This is free software, licensed under:

  The MIT (X11) License

=head1 BUGS AND LIMITATIONS

You can make new bug reports, and view existing ones, through the
web interface at L<https://rt.cpan.org/Public/Dist/Display.html?Name=Prophet>.

=head1 CONTRIBUTORS

=over 4

=item *

Alex Vandiver <alexmv@bestpractical.com>

=item *

Casey West <casey@geeknest.com>

=item *

Cyril Brulebois <kibi@debian.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Ioan Rogers <ioanr@cpan.org>

=item *

Jonas Smedegaard <dr@jones.dk>

=item *

Kevin Falcone <falcone@bestpractical.com>

=item *

Lance Wicks <lw@judocoach.com>

=item *

Nelson Elhage <nelhage@mit.edu>

=item *

Pedro Melo <melo@simplicidade.org>

=item *

Rob Hoelz <rob@hoelz.ro>

=item *

Ruslan Zakirov <ruz@bestpractical.com>

=item *

Shawn M Moore <sartak@bestpractical.com>

=item *

Simon Wistow <simon@thegestalt.org>

=item *

Stephane Alnet <stephane@shimaore.net>

=item *

Unknown user <nobody@localhost>

=item *

Yanick Champoux <yanick@babyl.dyndns.org>

=item *

franck cuny <franck@lumberjaph.net>

=item *

robertkrimen <robertkrimen@gmail.com>

=item *

sunnavy <sunnavy@bestpractical.com>

=back

=cut
