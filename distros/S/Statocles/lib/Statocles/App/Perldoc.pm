package Statocles::App::Perldoc;
our $VERSION = '0.087';
# ABSTRACT: Render documentation for Perl modules

use Statocles::Base 'Class';
use Statocles::Page::Plain;
use Scalar::Util qw( blessed );
use Pod::Simple::Search;
use Pod::Simple::XHTML;
with 'Statocles::App';

#pod =attr inc
#pod
#pod The directories to search for modules. Defaults to @INC.
#pod
#pod =cut

has inc => (
    is => 'ro',
    isa => ArrayRef[Path],
    # We can't check for existence, because @INC might contain nonexistent
    # directories (I think)
    default => sub { [ @INC ] },
    coerce => sub {
        my ( $args ) = @_;
        return [ map { Path::Tiny->new( $_ ) } @$args ];
    },
);

#pod =attr modules
#pod
#pod The root modules to find. Required. All child modules will be included. Any module that does
#pod not start with one of these strings will not be included.
#pod
#pod =cut

has modules => (
    is => 'ro',
    isa => ArrayRef[Str],
    required => 1,
);

#pod =attr index_module
#pod
#pod The module to use for the index page. Required.
#pod
#pod =cut

has index_module => (
    is => 'ro',
    isa => Str,
    required => 1,
);

#pod =attr weave
#pod
#pod If true, run the POD through L<Pod::Weaver> before converting to HTML
#pod
#pod =cut

has weave => (
    is => 'ro',
    isa => Bool,
    default => sub { 0 },
);

#pod =attr weave_config
#pod
#pod The path to the Pod::Weaver configuration file
#pod
#pod =cut

has weave_config => (
    is => 'ro',
    isa => Path,
    default => sub { './weaver.ini' },
    coerce => Path->coercion,
);

#pod =attr template_dir
#pod
#pod The directory (inside the theme directory) to use for this app's templates.
#pod Defaults to C<blog>.
#pod
#pod =cut

has '+template_dir' => (
    default => 'perldoc',
);

#pod =method pages
#pod
#pod     my @pages = $app->pages;
#pod
#pod Render the requested modules as HTML. Returns an array of L<Statocles::Page> objects.
#pod
#pod =cut

sub pages {
    my ( $self ) = @_;
    my @dirs = map { "$_" } @{ $self->inc };
    my $pod_base = 'https://metacpan.org/pod/';

    my %modules;
    for my $glob ( @{ $self->modules } ) {
        %modules = (
            %modules,
            %{ Pod::Simple::Search->new->inc(0)->limit_re( qr{^$glob} )->survey( @dirs ) },
        );

        # Also check for exact matches, for strange extensions
        for my $dir ( @dirs ) {
            my @glob_parts = split /::/, $glob;
            my $path = Path::Tiny->new( $dir, @glob_parts );
            if ( $path->is_file ) {
                $modules{ $glob } = "$path";
            }
        }
    }


    #; use Data::Dumper;
    #; say Dumper \%modules;

    my @pages;
    for my $module ( keys %modules ) {

        my $path = $modules{ $module };
        #; use Data::Dumper;
        #; say Dumper $path;

        # Weave the POD before trying to make HTML
        my $pod = $self->weave
                ? $self->_weave_module( $path )
                : Path::Tiny->new( $path )->slurp
                ;

        my $parser = Pod::Simple::XHTML->new;
        $parser->perldoc_url_prefix( $pod_base );
        $parser->$_('') for qw( html_header html_footer );
        $parser->output_string( \(my $parser_output) );
        $parser->parse_string_document( $pod );
        #; say $parser_output;

        my $dom = Mojo::DOM->new( $parser_output );
        for my $node ( $dom->find( 'a[href]' )->each ) {
            my $href = $node->attr( 'href' );

            # Rewrite links for modules that we will be serving locally
            if ( grep { $href =~ /^$pod_base$_/ } @{ $self->modules } ) {
                my ( $module, $section ) = $href =~ /^$pod_base([^#]+)(?:\#(.*))?$/;
                my $url = $self->url( $self->_module_href( $module ) );
                $node->attr( href => $section ? join( "#", $url, $section ) : $url );
            }
            # Add rel="external" for remaining external links
            elsif ( $href =~ m{(?:[^:]+:)?//} ) {
                $node->attr( rel => 'external' );
            }

        }

        my $source_path = "$module/source.html";
        $source_path =~ s{::}{/}g;

        my ( @parts ) = split m{::}, $module;
        my @crumbtrail;
        for my $i ( 0..$#parts ) {
            my $trail_module = join "::", @parts[0..$i];
            if ( $modules{ $trail_module } ) {
                push @crumbtrail, {
                    text => $parts[ $i ],
                    href => $self->url( $self->_module_href( $trail_module ) ),
                };
            }
            else {
                push @crumbtrail, {
                    text => $parts[ $i ],
                };
            }
        }

        my %page_args = (
            layout => $self->template( 'layout.html' ),
            template => $self->template( 'pod.html' ),
            title => $module,
            content => "$dom",
            app => $self,
            path => $self->_module_href( $module ),
            data => {
                source_path => $self->url( $source_path ),
                crumbtrail => \@crumbtrail,
            },
        );

        if ( $module eq $self->index_module ) {
            unshift @pages, Statocles::Page::Plain->new( %page_args );
	          $self->_highlight_page( $pages[0], 'pre > code' );
        }
        else {
            push @pages, Statocles::Page::Plain->new( %page_args );
	          $self->_highlight_page( $pages[-1], 'pre > code' );
        }

        # Add the source as a text file
        push @pages, Statocles::Page::Plain->new(
            path => $source_path,
            layout => $self->template( 'layout.html' ),
            template => $self->template( 'source.html' ),
            title => "$module (source)",
            content => Path::Tiny->new( $path )->slurp,
            app => $self,
            data => {
                doc_path => $self->url( $page_args{path} ),
                crumbtrail => \@crumbtrail,
            },
        );
        # unable to highlight source as source.html.ep uses <%== %> to escape html.
        # $self->_highlight_page( $pages[-1], 'pre' );
    }

    return @pages;
}

sub _highlight_page {
  my ( $self, $page, $sel ) = @_;
  # highlight only if site-wide highlighting is available
  return unless my $hl = $page->site->plugins->{highlight};
  # this add the highlight stylesheet to $page->links (template logic)
  $hl->highlight({page => $page}, Perl => '');
  # $page->dom calls $page->render 'set/making fast' links in the dom.
  my $codes = $page->dom->find($sel);
  if ($codes->first) {
    for my $node ($codes->each) {
      my $parent = $node->tag eq 'code' ? $node->parent : $node;
      $parent->replace($hl->highlight({}, Perl => $node->text));
    }
  } else {
    # remove if not used. path from Statocles::Plugin::Highlight#L159
    $page->dom->find('link[rel=stylesheet][href*=/plugin/highlight/]')
      ->each(sub { $_->remove });
  }

  return $page;
}

sub _module_href {
    my ( $self, $module ) = @_;
    if ( $module eq $self->index_module ) {
        return '/index.html';
    }

    my $page_url = "$module/index.html";
    $page_url =~ s{::}{/}g;
    return $page_url;
}

# Run Pod::Weaver on the POD in the given path
sub _weave_module {
    my ( $self, $path ) = @_;

    # Oh... My... GOD...
    my %errors;
    if ( !eval { require Pod::Weaver; 1; } ) {
        $errors{ 'Pod::Weaver' } = $@;
    }
    if ( !eval { require PPI; 1; } ) {
        $errors{ 'PPI' } = $@;
    }
    if ( !eval { require Pod::Elemental; 1; } ) {
        $errors{ 'Pod::Elemental' } = $@;
    }
    if ( !eval { require Encode; 1; } ) {
        $errors{ 'Encode' } = $@;
    }

    # Pod::Weaver 4.014 shipped with a bug that causes problems unless
    # we have a LEGAL section, which we do not presently allow users to
    # set. So warn them to upgrade if they have this version
    if ( defined($Pod::Weaver::VERSION) and $Pod::Weaver::VERSION == 4.014 ) {
        $errors{ 'Pod::Weaver' } = q{Pod::Weaver version 4.014 has a bug that will cause a fatal error when a LEGAL section isn't available. Please upgrade to version 4.015 or later.};
    }

    if ( keys %errors ) {
        die "Cannot weave POD: Error loading modules "
            . join( "\n", map { "$_: $errors{$_}" } keys %errors )
            ;
    }

    # Check for a config and give a friendly error message if missing.
    # The default exception thrown by a missing config is very difficult
    # to understand out of context
    if ( !$self->weave_config->parent->child( 'weaver.ini' )->is_file ) {
        die sprintf q{Cannot find Pod::Weaver config in "%s". Missing "weaver.ini" file?},
            $self->weave_config->parent;
    }

    my $perl_utf8 = Encode::encode( 'utf-8', Path::Tiny->new( $path )->slurp, Encode::FB_CROAK );
    my $ppi_document = PPI::Document->new( \$perl_utf8 ) or die PPI::Document->errstr;

    ### Copy/paste from Pod::Elemental::PerlMunger
    my $code_elems = $ppi_document->find(
        sub {
            return
                if grep { $_[ 1 ]->isa( "PPI::Token::$_" ) }
                qw(Comment Pod Whitespace Separator Data End);
            return 1;
        }
    );

    $code_elems ||= [];
    my @pod_tokens;

    my @queue = $ppi_document->children;
    while ( my $element = shift @queue ) {
        if ( $element->isa( 'PPI::Token::Pod' ) ) {
            # save the text for use in building the Pod-only document
            push @pod_tokens, "$element";
        }

        if ( blessed $element && $element->isa( 'PPI::Node' ) ) {
            # Depth-first keeps the queue size down
            unshift @queue, $element->children;
        }
    }

    ## Check for any problems, like POD inside of heredoc or strings
    my $finder = sub {
        my $node = $_[ 1 ];
        return 0
            unless grep { $node->isa( $_ ) }
        qw( PPI::Token::Quote PPI::Token::QuoteLike PPI::Token::HereDoc );
        return 1 if $node->content =~ /^=[a-z]/m;
        return 0;
    };

    if ( $ppi_document->find_first( $finder ) ) {
        warn "can't invoke Pod::Weaver on '$path': There is POD in string literals";
        return '';
    }

    my $pod_str = join "\n", @pod_tokens;
    my $pod_document = Pod::Elemental->read_string( $pod_str );

    ### MUNGE THE POD HERE!

    my $weaved_doc;
    eval {
        my $weaver = Pod::Weaver->new_from_config(
            { root => $self->weave_config->parent->stringify },
        );
        $weaved_doc = $weaver->weave_document({
            pod_document => $pod_document,
            ppi_document => $ppi_document,
        });
    };

    if ( $@ ) {
        die sprintf q{Error weaving POD for path "%s": %s}, $path, $@;
    }

    ### END MUNGE THE POD

    my $pod_text = $weaved_doc->as_pod_string;

    #; say $pod_text;
    return $pod_text;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Statocles::App::Perldoc - Render documentation for Perl modules

=head1 VERSION

version 0.087

=head1 DESCRIPTION

This application generates HTML from the POD in the requested modules.

=head1 ATTRIBUTES

=head2 inc

The directories to search for modules. Defaults to @INC.

=head2 modules

The root modules to find. Required. All child modules will be included. Any module that does
not start with one of these strings will not be included.

=head2 index_module

The module to use for the index page. Required.

=head2 weave

If true, run the POD through L<Pod::Weaver> before converting to HTML

=head2 weave_config

The path to the Pod::Weaver configuration file

=head2 template_dir

The directory (inside the theme directory) to use for this app's templates.
Defaults to C<blog>.

=head1 METHODS

=head2 pages

    my @pages = $app->pages;

Render the requested modules as HTML. Returns an array of L<Statocles::Page> objects.

=head1 AUTHOR

Doug Bell <preaction@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Doug Bell.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
