package Prophet::Web::Menu;
{
  $Prophet::Web::Menu::VERSION = '0.751';
}

# ABSTRACT: Handle the API for menu navigation
use Any::Moose;
use URI;

has cgi => (isa =>'CGI', is=>'ro');


has label => ( isa => 'Str', is => 'rw');


has parent => ( isa => 'Prophet::Web::Menu|Undef', is => 'rw', weak_ref => 1);


has sort_order => ( isa => 'Str', is => 'rw');
has render_children_inline => ( isa => 'Bool', is => 'rw', default => 0);
has url => ( isa => 'Str', is => 'bare');


has target => ( isa => 'Str', is => 'rw');


has class => ( isa => 'Str', is => 'rw');
has escape_label => ( isa => 'Bool', is => 'rw');
has server => (
    isa      => 'Prophet::Server',
    is       => 'ro',
    weak_ref => 1,

);


sub new {
    my $package = shift;
    my $args = ref( $_[0] ) eq 'HASH' ? shift @_ : {@_};

    my $parent = delete $args->{'parent'};

    # Class::Accessor only wants a hashref;
    my $self = $package->SUPER::new($args);

    # make sure our reference is weak
    $self->parent($parent) if defined $parent;

    return $self;
}


sub url {
    my $self = shift;
    $self->{url} = shift if @_;

    $self->{url} =
      URI->new_abs( $self->{url}, $self->parent->url . "/" )->as_string
      if defined $self->{url}
      and $self->parent
      and $self->parent->url;

    $self->{url} =~ s!///!/! if $self->{url};

    return $self->server->make_link_relative( $self->{url} );
}


sub active {
    my $self = shift;
    if (@_) {
        $self->{active} = shift;
        $self->parent->active( $self->{active} ) if defined $self->parent;
    }
    return $self->{active};
}


sub child {
    my $self  = shift;
    my $key   = shift;
    my $proto = ref $self || $self;

    if (@_) {
        $self->{children}{$key} = $proto->new(
            {
                parent     => $self,
                cgi        => $self->cgi,
                sort_order => (
                    $self->{children}{$key}{sort_order}
                      || scalar values %{ $self->{children} }
                ),
                label        => $key,
                escape_label => 1,
                server       => $self->server,
                @_
            }
        );

        # Figure out the URL
        my $child = $self->{children}{$key};
        my $url   = $child->url;

        # Activate it
        if ( defined $url and length $url and $self->cgi->path_info ) {

            # XXX TODO cleanup for mod_perl
            my $base_path = $self->cgi->path_info;
            chomp($base_path);

            $base_path =~ s/index\.html$//;
            $base_path =~ s/\/+$//;
            $url       =~ s/\/+$//;

            if ( $url eq $base_path ) {
                $self->{children}{$key}->active(1);
            }
        }
    }

    return $self->{children}{$key};
}


sub active_child {
    my $self = shift;
    foreach my $kid ( $self->children ) {
        return $kid if $kid->active;
    }
    return;
}


sub delete {
    my $self = shift;
    my $key  = shift;
    delete $self->{children}{$key};
}


sub children {
    my $self = shift;
    my @kids = values %{ $self->{children} || {} };
    @kids = sort { $a->sort_order <=> $b->sort_order } @kids;
    return wantarray ? @kids : \@kids;
}


sub render_as_menubar {
    my $self = shift;
    my $id   = 'menubar';    # XXX HACK

    my $buffer = '';
    $buffer .=
      $self->_render_as_menu_item( class => "page-nav sf-menu", id => $id );

    $buffer .= q|<script type="text/javascript"> 
                    $(document).ready(function(){ $("ul.page-nav").superfish(); });
                </script>|;
    return $buffer;
}

sub _render_as_menu_item {
    my $self = shift;
    my %args = ( class => '', first => 0, id => undef, @_ );
    my @kids = $self->children or return '';

    my $buffer = '';

    my $count = 1;

    $buffer .= '<ul class="' . $args{class} . '">' . "\n";
    for my $kid (@kids) {

        # We want to render the children of this child inline, so close
        # children.
        if ( $kid->render_children_inline and $kid->children ) {

            my @classes = ();
            push @classes, 'active' if $kid->active;

            $buffer .= $kid->as_link;
            $buffer .=
              $kid->_render_as_menu_item( first => ( $count == 1 ? 1 : 0 ) );
        }

        # It's a normal child
        else {
            $buffer .= (qq(<li>));
            $buffer .= ( $kid->as_link );
            $buffer .= $kid->_render_as_menu_item();
            $buffer .= qq{</li>\n};
        }
        $count++;
    }
    $buffer .= '</ul>' . "\n";
    return $buffer;
}


sub as_link {
    my $self = shift;

    if ( $self->url ) {
        my $label = $self->label;
        Prophet::Util::escape_utf8( \$label ) if ( $self->escape_label );
        return
            qq{<a href="@{[$self->url]}"}
          . ( $self->target ? qq{ target="@{[$self->target]}" } : '' )
          . ( $self->class  ? qq{ class="@{[$self->class]}" }   : '' ) . ">"
          . $label . '</a>'

          ;

    } else {
        return $self->label;
    }
}

__PACKAGE__->meta->make_immutable;
no Any::Moose;

1;

__END__

=pod

=head1 NAME

Prophet::Web::Menu - Handle the API for menu navigation

=head1 VERSION

version 0.751

=head1 ATTRIBUTES

=head2 label [STRING]

Sets or returns the string that the menu item will be displayed as.

=head2 parent [MENU]

Gets or sets the parent L<Prophet::Web::Menu> of this item; this defaults to
null. This ensures that the reference is weakened.

=head2 sort_order [NUMBER]

Gets or sets the sort order of the item, as it will be displayed under the
parent.  This defaults to adding onto the end.

=head2 target [STRING]

Get or set the frame or pseudo-target for this link. something like L<_blank>

=head2 link

Gets or set a Jifty::Web::Link object that represents this menu item. If you're
looking to do complex ajaxy things with menus, this is likely the option you
want.

=head1 METHODS

=head2 new PARAMHASH

Creates a new L<Prophet::Web::Menu> object.  Possible keys in the I<PARAMHASH>
are C<label>, C<parent>, C<sort_order>, C<url>, and C<active>.  See the
subroutines with the respective name below for each option's use.

=head2 url

Gets or sets the URL that the menu's link goes to.  If the link provided is not
absolute (does not start with a "/"), then is is treated as relative to it's
parent's url, and made absolute.

=head2 active [BOOLEAN]

Gets or sets if the menu item is marked as active.  Setting this cascades to
all of the parents of the menu item.

=head2 child KEY [, PARAMHASH]

If only a I<KEY> is provided, returns the child with that I<KEY>.

Otherwise, creates or overwrites the child with that key, passing the
I<PARAMHASH> to L<Jifty::Web::Menu/new>.  Additionally, the paramhash's
C<label> defaults to the I<KEY>, and the C<sort_order> defaults to the
pre-existing child's sort order (if a C<KEY> is being over-written) or the end
of the list, if it is a new C<KEY>.

=head2 active_child

Returns the first active child node, or C<undef> is there is none.

=head2 delete KEY

Removes the child with the provided I<KEY>.

=head2 children

Returns the children of this menu item in sorted order; as an array in array
context, or as an array reference in scalar context.

=head2 render_as_menubar [PARAMHASH]

Render menubar with YUI menu, suitable for an application's menu. It can
support arbitrary levels of submenu.

=head2 as_link

Return this menu item as a C<Jifty::Web::Link>, either the one we were
initialized with or a new one made from the C</label> and C</url>

If there's no C</url> and no C</link>, renders just the label.

=head2 class [STRING]

Gets or sets the CSS class the link should have in addition to the default
classes.  This is only used if C<link> isn't specified.

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
