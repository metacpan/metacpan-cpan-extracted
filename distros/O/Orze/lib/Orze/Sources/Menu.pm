package Orze::Sources::Menu;

use strict;
use warnings;

use Data::Dump qw(dump);

use base "Orze::Sources";

=head1 NAME

Orze::Sources::Menu - Build a page tree, suitable for a menu

=head1 DESCRIPTION

If there is a base attribute, use the value as the root of the tree (it
expects the name of a page).
Otherwise, use the current page (you can also set C<base="."> if you
want).

If C<base="/">, use the root of the website as the root of the tree.

All pages without a title variable or with the C<notinmenu> attribute
set to 1 will be ignored.

The output is a list of hash pointer of the form:

  {
  		name => 'name_of_the_page',
  		title => 'Title of the page',
  		extension => 'extension_of_the_page',
  		path => 'path/to/name_of_the_page',
  		submenu => pointer to a list of the same form,
  }

=head1 METHOD

=head2 evaluate

=cut

sub evaluate {
    my ($self) = @_;

    my $page = $self->{page};
    my $var  = $self->{var};

    my $basename;
    if (defined($var->att('base'))) {
        $basename = $var->att('base');
    }
    else {
        $basename = ".";
    }

    my $notinmenu;
    if (defined($page->att('notinmenu'))) {
        $notinmenu = $page->att('notinmenu');
    }
    else {
        $notinmenu = 0;
    }

    my $base;
    if ($basename eq "/") {
        $base = $page->root;
    }
    else {
        if ($basename eq ".") {
            $base = $page;
        }
        else {
            $base = $page->root->first_child('page[@name="' . $basename . '"]');
        }
    }

    my @pages = $base->children('page');
    my @menu = ();
    foreach (@pages) {
        my $notinmenu;
        if (defined($_->att('notinmenu'))) {
            $notinmenu = $_->att('notinmenu');
        }
        else {
            $notinmenu = 0;
        }

        my $title = $_->field('var[@name="title"]');
#               print STDERR $title, "\n"; # ça devient de l'iso ici !!!
        if ($title && not $notinmenu) {
            my $name = $_->att('name');
            my $extension = $_->att('extension');
            my $path = $_->att('path');

            my @subpages = $_->children('page');
            my @submenu = ();
            foreach my $p (@subpages) {
                my $title = $p->field('var[@name="title"]');
                if ($title) {
                    my $name = $p->att('name');
                    my $extension = $p->att('extension');
                    my $path = $p->att('path');
                    push @submenu, {
                        name => $name,
                        title => $title,
                        extension => $extension,
                        path => $path,
                    };
                }
            }

            push @menu, {
                        name => $name,
                        title => $title,
                        extension => $extension,
                        path => $path,
                        submenu => \@submenu,
                    };
        }
    }

    if ($var->att('debug')) {
        print STDERR dump(\@menu);
    }

    return \@menu;
}

1;
