package Namespace::Dispatch;
our $VERSION = '0.07';

use 5.010;
use UNIVERSAL::filename;

sub import {
    my $pkg    = shift;
    my $caller = caller;
    my $meta   = ref($caller->meta) if $caller->can("meta");

    if ( $meta && $meta =~ m/(Class$|Role$)/ ) {
        eval qq{ use Moose::Role };
        Moose::Util::apply_all_roles($caller, $pkg, {-excludes => "import"});
    } else {
        for (qw(has_leaf dispatch leaves)) {
            *{$caller . "::" . $_} = *{$_};
        }
    }

}

sub has_leaf {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my $name    = shift;
    my @leaves = @{$class->leaves} if $class->can("leaves");
    if ( $name ~~ @leaves ) {
        return $class . "::" . ucfirst($name);
    } else {
        return 0;
    }
}

sub dispatch {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my $next    = shift;
    my $handler = $class->has_leaf($next);

    if ($handler) {

        eval qq{ use $handler };
        die $@ if $@;

        if ($handler->can("dispatch")) {
            return $handler->dispatch(@_);
        } else {
            die "$handler is not set up yet (forgot to use Namespace::Dispatch?)";
        }

    } else {
        return $class;
    }

}

sub leaves {
    my $class   = ref($_[0]) ? ref(shift) : shift;
    my $file = $class->filename;
    $file =~ s{.pm$}{}g;
    use File::Basename;
    my @submodules = map { $_ = lc basename($_) } glob "$file/*.pm";
    map { $_ =~ s{\.pm$}{}; } @submodules;
    [@submodules];
}

1;
__END__

=head1 NAME

Namespace::Dispatch - A dispatcher treating namespaces as a tree

=head1 SYNOPSIS

    # lib/Foo.pm
    package Foo;
    use Namespace::Dispatch;

    1;

    # lib/Foo/Bar.pm
    package Foo::Bar;
    use Namespace::Dispatch;

    1;

    # lib/Foo/Bar/Baz.pm
    package Foo::Bar::Baz;
    use Namespace::Dispatch;

    1;

    # lib/Foo/Bar/Baz/Next.pm
    package Foo::Bar::Baz::Next;
    use Namespace::Dispatch;

    1;

    # any.pl
    package main;
    use Foo;
    Foo->dispatch(qw(bar baz));            #=> Foo::Bar::Baz
    Foo->dispatch(qw(bar baz next));       #=> Foo::Bar::Baz::Next
    Foo::Bar->dispatch(qw(bar baz next));  #=> Foo::Bar::Baz::Next
    Foo->dispatch(qw(hello world));        #=> Foo

=head1 DESCRIPTION

Namespace::Dispatch is designed for the purpose that tasks are broke into a set of relevant, hierarchical modules.
Implicit dispatching ability was attached into these modules when they are declared as members of this set.  Any node in
this hierarchy can serve the dispatching requests in recursive manner. That is, Any tree-like routing system can adopt
the abstraction under the hood with its own invoking mechanism.

=head1 AUTHOR

shelling E<lt>navyblueshellingford@gmail.comE<gt>

=head1 SEE ALSO

L<App::LDAP>

=head1 LICENSE

The MIT License

=cut
