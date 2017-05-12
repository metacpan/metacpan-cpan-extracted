package SoggyOnion;
use strict;
use warnings;
use Carp;

our $VERSION = '0.04';

# soggyonion and the default plugins use the Template Toolkit
use Template;

# which template file to use for this module
use constant TEMPLATE_FILE => 'main.tt2';

# Parallel::ForkManager threads the page creation. i sure hope that
# Cache::File does the right thing in terms of locking..
use Parallel::ForkManager;

# how many pages to create at once
use constant MAX_THREADS => 10;

# use Cache::FileCache to cache the results of plugins
use Cache::FileCache;

# use IO::Scalar to buffer the output of threads so the output appears
# in the correct order
use IO::Scalar;

#------------------------------------------------------------------------

# preload base classes
use SoggyOnion::Plugin;
use SoggyOnion::Resource;

# a simple accessor for our options -- makes the code look particularly
# neat in plugins
our $OPTIONS;

sub options {
    my ( $self, $value ) = @_;
    if ($value) {
        croak "configuration error: options isn't a hash\n"
            unless ref $value eq 'HASH';
        $OPTIONS = $value;
    }
    return $OPTIONS;
}

# hopefully plugins that get pages will use this as the User-Agent. it
# can be set by exporting the $ua variable for LWP::Simple
# ($LWP::Simple::ua) or setting the agent option for LWP::UserAgent
# objects.
sub useragent {
    return "SoggyOnion/$VERSION";
}

# here's the meaty subroutine that is called from the executable. the
# executable's job is to parse a configuration file, retrieve a hash of
# options and call SoggyOnion->options with it, then retrieve a hash
# that is the layout of the pages and call SoggyOnion->generate with it.
sub generate {
    my ( $self, $layout ) = @_;
    die "configuration error: options isn't defined\n"
        unless $self->options;
    die "configuration error: layout isn't an array\n"
        unless ref $layout eq 'ARRAY';

    # determine resource class
    $self->options->{resourceclass} ||= 'SoggyOnion::Resource';

    # initialize our cache
    my $cache;
    eval {
        $cache = Cache::FileCache->new(
            { cache_root => $self->options->{cachedir}, } );
    };
    die "error creating cache: $@\n"
        if $@;

    # initialize templates
    my $template = Template->new(
        INCLUDE_PATH => $self->options->{templatedir},
        OUTPUT_PATH  => $self->options->{outputdir},
    );

    # initialize thread manager
    my $fm = Parallel::ForkManager->new(MAX_THREADS);

    # process all pages
    foreach my $page (@$layout) {

        # fork off!
        my $pid = $fm->start and next;

        # set up buffer so that the output for each page generation is
        # only printed at the end of the thread. note: i ran into
        # problems when trying to capture STDERR to the same filehandle,
        # and that's probably the problem :)
        my $output;
        my $output_fh = IO::Scalar->new( \$output );
        local *REAL_STDOUT = *STDOUT;
        local *STDOUT      = $output_fh;

        # a little feedback
        print "creating page $page->{name} ($page->{title})\n";

        # construct the body for each page by grabbing the content
        # from each item
        my $body = '';
        unless ( ref $page->{items} eq 'ARRAY' ) {
            warn "Error: items for page $page->{name} isn't an array\n";
            $fm->finish;
            next;
        }
        foreach my $item ( @{ $page->{items} } ) {

            # let SoggyOnion/Resource.pm figure out what kind of
            # resource this is and simply return an object. this is
            # i made it easy to specify a "resourceclass" option in the
            # config, so that you can extend SoggyOnion::Resource to
            # automatically determine a class using your plugins
            my $resource = $self->options->{resourceclass}->new($item);
            unless ( ref $resource ) {
                warn "\t\tcouldn't find appropriate handler for item $item\n";
                $fm->finish;
                next;
            }
            my $id = $resource->id;
            print "\tprocessing item ", $id, "\n";

            # is the resource already cached? check and see by
            # comparing the resource's modification time against the
            # modification time of the cached copy. if the resource's
            # mod time is newer, regenerate the content.
            # (see Cache::Cache and Cache::Object for more info)
            my $content = 'empty content';
            if (   $cache->get_object($id)
                && $cache->get_object($id)->get_created_at
                >= $resource->mod_time )
            {
                print "\t\tcache is up to date\n";
                $content = $cache->get($id);
            }
            else {
                $content = eval { $resource->content };
                if ($@) {
                    $content
                        = "error generating this resource: <pre>$@</pre>";
                    warn "\t\terror generating: $@\n";
                    $fm->finish;
                    next;
                }
                $cache->set( $id => $content );
            }

            # add the item to the body, set the <DIV>'s id attribute to
            # the id of the item
            $body .= qq(<div id=") . $id . qq(">\n);
            $body .= $content;
            $body .= qq(</div>\n);
        }

        # create the output file
        $template->process(
            TEMPLATE_FILE,
            {   thispage => $page,
                allpages => $layout,
                content  => $body,
            },
            $page->{name},
            )
            or warn "\t\t" . $template->error . "\n";

        # print buffer to output
        print REAL_STDOUT $output;

        # finish with fork
        $fm->finish;
    }

    # cleanup all the children
    $fm->wait_all_children;

    print "done!\n";
}

1;
__END__

=head1 NAME

SoggyOnion - RSS and other arbitrary content aggregatron

=head1 SYNOPSIS

    $ soggyonion-install
    $ vim/emacs config.yaml
    $ soggyonion config.yaml
    $ crontab -e

=head1 DESCRIPTION

B<NOTE:> This is a pre-release. I need to add tests, among other things. Functionality is here, though.

SoggyOnion is an RSS and arbitrary content aggregator that produces static
pages. It was written to be easily installable and configurable as well as
trivial to extend. It is meant for people that want to view RSS feeds and other
scraped content as a web page and want minimal setup and configuration.

=head2 Installation

The module creates two executables, F<soggyonion> and
F<soggyonion-install>. Once the SoggyOnion module is installed, do the
following:

=over 4

=item 1. Change to a directory where you'd like to keep the configuration
file and defaults, then run the F<soggyonion-install> command. This will
extract a handful of files to the current directory.

=item 2. Edit the F<config.yaml> configuration file. To get started
quickly, just make sure the four options in the first section are
correct.

=item 3. Run the F<soggyonion> command with th

=back

=head2 Customizing the Output

All sources of content are found in the F<config.yaml> file. The main
template, F<templates/main.tt2>, contains all the CSS. 

=head2 Extending

See: L<SoggyOnion::Plugin>

=head2 Why is it called "SoggyOnion?"

I purchased the domain C<soggyonion.com> on complete impulse. When
I wrote this I finally made use of that silly domain and I kept the
name.

I not longer own this domain.

=head2 Why don't I use (RSS utility here)?

If you like it better, please do. I welcome all suggestions and
constructive criticism (a.k.a. complaints), so fire away :-)

I wanted a tool where I could specify a few sources of RSS/RDF and have
it produce categorized, static pages for me that could be easily
customized through templates and CSS. I'm also not yet convinced that
everything should be RSS -- SoggyOnion can be used as a front-end for
any scraped content.

=head1 SEE ALSO

L<SoggyOnion::Plugin>, L<XML::RSS>, L<YAML>

=head1 AUTHOR

Ian Langworth, C<< <ian@cpan.org> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Ian Langworth

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
