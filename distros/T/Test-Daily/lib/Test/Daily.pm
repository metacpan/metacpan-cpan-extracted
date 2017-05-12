package Test::Daily;

=head1 NAME

Test::Daily - daily testing reports

=head1 SYNOPSIS

    use Test::Daily;
    my $td = Test::Daily->new();
    $td->extract_tarball('my-test-tap-archive_version_arch.tar.gz');
    $td->update_site_makefile;
    $td->update_project_makefile($folder);
    $td->update_test_makefile($folder);
    $td->update_test_summary();
    $td->update_project_summary();
    $td->update_site_summary();

See `test-daily` script.
    
=head1 DESCRIPTION

=head1 USAGE

=head2 TAP::Harness::Archive

Use L<TAP::Harness::Archive> to create tarball of the test output. Simply
install it and run F<prove> with C<--archive> option.

    prove --archive name_version_arch.tar.gz
    prove --archive test-project-name_20090927_i386.tar.gz

=head2 Create pages with test output

On server where the pages will be hosted (generated):

    test-daily tarball test-project-name_20090927_i386.tar.gz
    test-daily site-makefile
    test-daily make

=cut

use Moose;
use Test::Daily::SPc;
use Config::Tiny;
use Carp 'croak';
use File::Path 'mkpath';
use File::Basename 'basename';
use Archive::Extract;
use Path::Class 'dir', 'file';
use Template;
use Template::Constants qw( :debug );
use TAP::Formatter::HTML '0.08';
use TAP::Harness;
use JSON::Util;
use YAML::Syck ();
use XML::LibXML;
use HTML::Entities 'encode_entities';

our $VERSION = '0.02';

has 'datadir' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => sub { dir(Test::Daily::SPc->datadir, 'test-daily') },
    lazy    => 1,
);
has 'webdir' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => sub { dir(Test::Daily::SPc->webdir, 'test-daily') },
    lazy    => 1,
);
has 'config_file' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => sub { dir(Test::Daily::SPc->sysconfdir, 'test-daily', 'test-daily.conf') },
    lazy    => 1,
);
has 'config' => (
    is      => 'rw',
    isa     => 'Config::Tiny',
    default => sub { Config::Tiny->read( $_[0]->config_file ) or die 'failed to open config file - "'.$_[0]->config_file.'"' },
    lazy    => 1,
);
has 'tt_config' => (
    is      => 'rw',
    isa     => 'HashRef',
    default => sub {
        $_[0]->config->{'tt'}
        || {
            'INCLUDE_PATH' => [ dir($_[0]->datadir, 'tt-lib')->stringify, dir($_[0]->datadir, 'tt')->stringify ],
            'DEBUG'        => DEBUG_UNDEF,
        }
    },
    lazy    => 1,
);
has 'ttdir' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => sub { dir($_[0]->datadir, 'tt') },
    lazy    => 1,
);
has 'ttlibdir' => (
    is      => 'rw',
    isa     => 'Path::Class::Dir',
    default => sub { dir($_[0]->datadir, 'tt-lib') },
    lazy    => 1,
);
has 'site_prefix' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $_[0]->config->{'main'}->{'site_prefix'} || '/test-server' },
    lazy    => 1,
);
has 'site_hostname' => (
    is      => 'rw',
    isa     => 'Str',
    default => sub { $_[0]->config->{'main'}->{'site_hostname'} || 'localhost' },
    lazy    => 1,
);
has 'tt' => (
    is      => 'rw',
    isa     => 'Template',
    default => sub { Template->new($_[0]->tt_config) || die $Template::ERROR, "\n" },
    lazy    => 1,
);

our @aggregate_methods = qw(
    get_status
    elapsed_timestr
    all_passed
    
    failed
    parse_errors
    passed
    planned
    skipped
    todo
    todo_passed
    wait
    exit
    
    total
    has_problems
    has_errors
);


=head1 METHODS

=head2 new()

Object constructor.

=head2 extract_tarball($tarball)

Extract L<TAP::Harness::Archive>.

=cut

sub extract_tarball {
    my $self    = shift;
    my $tarball = shift or croak 'pass tarball as argument';
    
    croak 'tarball name "'.basename($tarball).'" format unknown'
        if basename($tarball) !~ m/^(.+)_(.+)_(.+)\.(?:tar\.gz|zip)$/xms;
    my ($name, $version, $arch) = ($1, $2, $3);
    
    my $ae = Archive::Extract->new( archive => $tarball );
    my $extract_to;
    my $i = 0;
    my $index = '';
    do {
        $extract_to = dir($self->webdir, $name, $version.'_'.$arch.$index);
        $index = sprintf('_%03d', $i);
        $i++;
    } while -d $extract_to;
    mkpath($extract_to->stringify) or die $extract_to.' - '.$!;
    $ae->extract( to => $extract_to);
    
    # remove Makefile needs to be regenerated
    unlink(dir($self->webdir, $name, 'Makefile')->stringify);
}

sub _all_folders {
    my $self = shift;
    my $path = dir();
    my @folders;
    while (my $file = $path->next) {
        next if not -d $file;
        next if $file eq $path;
        
        $file = basename($file);        
        next if $file eq '..';
        next if $file eq '_td'; 
               
        push @folders, $file;
    }
    return @folders;
}

sub _process {
    my $self         = shift;
    my $template     = shift or die 'set template parameter';
    my $out_filename = shift or die 'set out_filename parameter';
    my $more_tt_args = shift || {};

    my $tt   = $self->tt;
    
    $self->tt->process(
        $template,
        {
            'folders'  => [ $self->_all_folders ],
            'ttdir'    => $self->ttdir,
            'ttlibdir' => $self->ttlibdir,
            'json'     => JSON::Util->new(),
            %{$more_tt_args},
        },
        $out_filename,
    ) || die $self->tt->error(), "\n";;
}

sub _process_summary {
    my $self         = shift;
    
    my %summary;
    my $all_passed = 0;
    my $has_errors = 0;
    foreach my $folder ($self->_all_folders) {
        my $folder_summary = JSON::Util->decode([ $folder, 'summary.json' ]);
        $all_passed += $folder_summary->{'all_passed'}->[0] || 0;
        $has_errors += $folder_summary->{'has_errors'}->[0] || 0;
    }
    $summary{'all_passed'} = [ $all_passed ];
    $summary{'has_errors'} = [ $has_errors ];
    
    JSON::Util->encode(\%summary, [ 'summary.json' ]);
}

=head2 update_site_makefile

=cut

sub update_site_makefile {
    my $self = shift;
    chdir($self->webdir);
    $self->_process('Makefile-site.tt2', 'Makefile');
}

=head2 update_project_makefile($folder)

=cut

sub update_project_makefile {
    my $self   = shift;
    my $folder = shift or die 'pass folder argument';
    chdir($folder);
    $self->_process('Makefile-project.tt2', 'Makefile', { 'curfolder' => $folder });
}

=head2 update_test_makefile($folder)

=cut

sub update_test_makefile {
    my $self    = shift;
    my $folder  = shift or die 'pass folder argument';
    my $project = shift or die 'pass project name';
    chdir($folder);
    $self->_process('Makefile-test.tt2', 'Makefile', { 'curfolder' => $folder, 'project' => $project });
}

=head2 update_test_summary

=cut

sub update_test_summary {
    my $self = shift;
    
    my @tests = glob( 't/*.t' );
    my $fmt = TAP::Formatter::HTML->new;
    $fmt
        ->js_uris([$self->config->{'main'}->{'site_prefix'}.'_td/jquery-1.3.2.js', $self->config->{'main'}->{'site_prefix'}.'_td/default_report.js' ])
        ->css_uris([$self->config->{'main'}->{'site_prefix'}.'_td/default_page.css', $self->config->{'main'}->{'site_prefix'}.'_td/default_report.css'])
        ->inline_css('')
        ->force_inline_css(0)
        ->inline_js('');
    $fmt->output_file('index.html-new');
    $fmt->verbosity(-2);

    my $harness = TAP::Harness->new({
        formatter => $fmt,
        merge     => 1,
        lib       => [ 'lib', 'blib/lib', 'blib/arch' ],
        exec      => [ 'cat' ],
    });

    my $aggregate = $harness->runtests( @tests );

    # write test summary
    JSON::Util->encode(
        {
            (map { $_ => [ $aggregate->$_ ] } @aggregate_methods),
            'meta' => YAML::Syck::LoadFile('meta.yml'),
        },
        'summary.json'
    );
    
    rename('index.html-new', 'index.html');
}

=head2 update_project_summary

=cut

sub update_project_summary {
    my $self = shift;
    $self->_process_summary();
    $self->_process('project.tt2', 'index.html');
}

=head2 update_site_summary

=cut

sub update_site_summary {
    my $self = shift;
    $self->_process_summary();
    $self->_process('site.tt2', 'index.html');    
}

=head2 run_make($target)

=cut

sub run_make {
    my $self = shift;
    my $what = shift;
    
    system('cd '.$self->webdir->stringify.'; make'.($what ? ' '.$what : '')) and die $!;
}

=head2 summary2rssfeed

=cut

sub summary2rssfeed {
    my $self = shift;
    my $path = shift;
    my $title = $path;
    $title =~ s{/}{_};

    $self->_process(
        'summary2rssfeed.tt2',
        'rss.xml',
        {
            'title' => $title,
            'link'  => 'http://'.$self->site_hostname.$self->site_prefix.$path.'/',
        }
    );
}

=head2 aggregatefeeds

=cut

sub aggregatefeeds {
    my $self  = shift;
    my $title = shift;
    
    my $parser = XML::LibXML->new;
    my $xpc = XML::LibXML::XPathContext->new();
    
    my @entries;
    foreach my $folder ($self->_all_folders) {
        my $feed = $parser->parse_file(file($folder, 'rss.xml'));
        $xpc->registerNs('atom', 'http://www.w3.org/2005/Atom');
        push @entries, $xpc->findnodes('/atom:feed/atom:entry', $feed);
    }
    @entries =
        sort { $a->{'updated'} cmp $b->{'updated'} }
        map {{
            'title'   => encode_entities($xpc->findvalue('atom:title', $_), '<>&'),
            'link'    => encode_entities($xpc->findvalue('atom:link/@href', $_), '<>&'),
            'id'      => encode_entities($xpc->findvalue('atom:id', $_), '<>&'),
            'updated' => encode_entities($xpc->findvalue('atom:updated', $_), '<>&'),
            'summary' => encode_entities($xpc->findvalue('atom:summary', $_), '<>&'),
    }} @entries;
    my @ids = map { $_->{'id'} } @entries;

    $self->_process(
        'atom.tt2',
        'rss.xml',
        {
            'title'   => $title || 'Test::Daily',
            'link'  => 'http://'.$self->site_hostname.$self->site_prefix.($title ? $title.'/' : ''),
            'ids'     => \@ids,
            'entries' => \@entries,
        }
    );
    
    @entries = grep { $_->{'title'} =~ m/^FAIL \s/xms } @entries;
    @ids = map { $_->{'id'} } @entries;
    
    $self->_process(
        'atom.tt2',
        'rss-fail.xml',
        {
            'title'   => $title || 'Test::Daily',
            'link'  => 'http://'.$self->site_hostname.$self->site_prefix.($title ? $title.'/' : ''),
            'ids'     => \@ids,
            'entries' => \@entries,
        }
    );
}


'hu?';


__END__

=head1 AUTHOR

Jozef Kutej

=cut

=head1 AUTHOR

Jozef Kutej, C<< <jkutej at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-test-daily at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Test-Daily>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Test::Daily


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Test-Daily>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Test-Daily>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Test-Daily>

=item * Search CPAN

L<http://search.cpan.org/dist/Test-Daily>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

Copyright 2009 Jozef Kutej, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut
