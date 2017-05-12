use strict;
use warnings;

package Prophet::Server::View;
{
  $Prophet::Server::View::VERSION = '0.751';
}
use base 'Template::Declare';

use Template::Declare::Tags;
use URI::file;

# Prophet::Server::ViewHelpers overwrites the form {} function provided by
# Template::Declare::Tags. ViewHelpers uses Exporter::Lite which does not "use
# warnings". When prove -w or make test is run, $^W is set which turns on
# warnings in Exporter::Lite (most importantly, redefinition warnings). We
# don't want to warn about this specific redefinition, so we swap out
# $SIG{__WARN__} to shut up about it.

BEGIN {
    no warnings 'redefine';
    my $old_warn = $SIG{__WARN__} || sub { warn $_[0] };
    local $SIG{__WARN__} = sub {
        my $warning = shift;
        $old_warn->($warning)
          unless $warning =~
          /Subroutine Prophet::Server::View::form redefined /;
    };
    require Prophet::Server::ViewHelpers;
    Prophet::Server::ViewHelpers->import;
}
use Params::Validate;
use Prophet::Web::Menu;

our $APP_HANDLE;

sub app_handle {
    my $self = shift;
    $APP_HANDLE = shift if (@_);
    return $APP_HANDLE;
}

our $CGI;

sub cgi {
    my $self = shift;
    $CGI = shift if (@_);
    return $CGI;
}

our $MENU;

sub page_nav {
    my $self = shift;
    $MENU = shift if (@_);
    return $MENU;
}

our $SERVER;

sub server {
    my $self = shift;
    $SERVER = shift if (@_);
    return $SERVER;

}

template '_prophet_autocompleter' => sub {
    my $self = shift;
    my %args;
    for (qw(q function record type class prop)) {
        $args{$_} = $self->cgi->param($_);
    }
    my $obj = Prophet::Util->instantiate_record(
        class      => $self->cgi->param('class'),
        uuid       => $self->cgi->param('uuid'),
        app_handle => $self->app_handle
    );
    my @possible;
    if ($obj) {
        my $canon = { $args{prop} => $args{q} };
        $obj->canonicalize_prop( $args{'prop'}, $canon, {} );
        if ( $canon->{ $args{prop} } ne $args{q} ) {
            push @possible, $canon->{ $args{'prop'} };
        }
    }
    if ( $obj->loaded ) {
        push @possible, $obj->prop( $args{'prop'} );
    } else {
        my $params = { $args{'prop'} => undef };
        $obj->default_props($params);
        push @possible, $params->{ $args{'prop'} };

        # XXX fill in defaults;
    }

    push @possible, $obj->recommended_values_for_prop( $args{'prop'} );

    my %seen;
    for ( grep { defined && !$seen{$_}++ } @possible ) {
        outs( $_ . "\n" );    #." | ".$_."\n");

    }

};

sub default_page_title {'Prophet'}

template head => sub {
    my $self = shift;
    my @args = shift;
    head {
        meta {
            attr {
                content      => "text/html; charset=utf-8",
                'http-equiv' => "Content-Type"
            };
        };
        title { shift @args };
        for ( $self->server->css ) {
            link {
                {
                    rel is 'stylesheet',
                    href is link_to($_),
                    type is "text/css",
                    media is 'screen'
                }
            };
        }
        for ( $self->server->js ) {
            script {
                { src is link_to($_), type is "text/javascript" }
            };
        }
    }

};

template footer => sub { };
template header => sub {
    my $self  = shift;
    my $title = shift;
    if ( $self->page_nav ) {
        div {
            { class is 'page-nav' };
            outs_raw( $self->page_nav->render_as_menubar );
        };
    }
    h1 {$title};
};

template '/' => page {
    h1 {"This is a Prophet replica!"};
};

sub record_table {
    my %args = validate(
        @_,
        {
            records    => 1,
            url_prefix => { default => '' },
        }
    );

    my $records = $args{records};
    my $prefix  = $args{url_prefix};

    table {
        my @items = $records ? $records->items : ();
        if (@items) {
            my @headers = $items[0]->_parse_format_summary;
            row {
                for (@headers) {
                    th { $_->{prop} };
                }
            }
        }

        for my $record ( sort { $a->luid <=> $b->luid } @items ) {
            my $type  = $record->type;
            my $uuid  = $record->uuid;
            my @atoms = $record->format_summary;

            row {
                attr { id => "$type-$uuid", class => "$type" };

                for my $i ( 0 .. $#atoms ) {
                    my $atom = $atoms[$i];
                    my $prop = $atom->{prop};

                    cell {
                        attr { class => "prop-$prop", };

                        if ( $i == 0 ) {
                            a {
                                attr { href => link_to("$prefix$uuid.html"), };
                                outs $atom->{value};
                            }
                        } else {
                            outs $atom->{value};
                        }
                    }
                }
            }
        }
    }
}

template record_table =>

  page {
    my $self    = shift;
    my $records = shift;
    record_table( records => $records );
  };

template record => page {
    my $self   = shift;
    my $record = shift;

    p {
        a {
            attr { href => link_to("index.html"), };
            outs "index";
        }
    }
    hr {} dl {
        dt {'UUID'} dd { $record->uuid } dt {'LUID'} dd { $record->luid };

        my $props = $record->get_props;
        for my $prop ( sort keys %$props ) {
            dt {$prop} dd { $props->{$prop} };
        }
    };

    hr {} h3 {"History"};

    show record_changesets => $record;

    # linked collections
    for my $method ( $record->collection_reference_methods ) {
        my $collection = $record->$method;
        next if $collection->count == 0;

        my $type = $collection->record_class->type;

        hr {} h3 {"Linked $type records"}

        record_table(
            records    => $collection,
            url_prefix => "../$type/",
        );
    }

};

private template record_changesets => sub {
    my $self   = shift;
    my $record = shift;
    my $uuid   = $record->uuid;

    ol {
        for my $change ( $record->changes ) {
            my @prop_changes = $change->prop_changes;
            next if @prop_changes == 0;

            if ( @prop_changes == 1 ) {
                li { $prop_changes[0]->summary };
                next;
            }

            li {
                ul {
                    for my $prop_change (@prop_changes) {
                        li {
                            outs $prop_change->summary;
                        }
                    }
                }
            }
        }
    }
};

sub generate_changeset_feed {
    my $self = shift;
    my %args = validate(
        @_,
        {
            handle => 1,
            title  => 0,
        }
    );

    my $handle = $args{handle};
    my $title = $args{title} || 'Prophet replica ' . $handle->uuid;

    require XML::Atom::SimpleFeed;

    my $feed = XML::Atom::SimpleFeed->new(
        id     => "urn:uuid:" . $handle->uuid,
        title  => $title,
        author => $self->app_handle->current_user_email,
    );

    my $newest = $handle->latest_sequence_no;
    my $start  = $newest - 20;
    $start = 0 if $start < 0;

    $handle->traverse_changesets(
        after    => $start,
        callback => sub {
            my %args = (@_);
            $feed->add_entry(
                title => 'Changeset ' . $args{changeset}->sequence_no,

                # need uuid or absolute link :(
                category => 'Changeset',
            );
        },
    );

    return $feed;
}

sub link_to ($) {
    my $link = shift;
    return URI::file->new($link)->rel( "file://" . $ENV{REQUEST_URI} );
}
1;

__END__

=pod

=head1 NAME

Prophet::Server::View

=head1 VERSION

version 0.751

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
