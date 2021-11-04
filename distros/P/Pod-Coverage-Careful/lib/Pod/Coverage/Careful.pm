package Pod::Coverage::Careful;

use strict;
use warnings;

our $VERSION = "v1.1.0";

use B;
use Devel::Symdump;
use Pod::Coverage;
our @ISA = qw(Pod::Coverage);

BEGIN { *TRACE_ALL = \&Pod::Coverage::TRACE_ALL; }

sub name_of_coderef {
    require B;
    my($coderef) = @_;

    my $cv = B::svref_2object($coderef);
    return unless $cv->isa("B::CV");

    my $gv = $cv->GV;
    return if $gv->isa("B::SPECIAL");

    my $subname  = $gv->NAME;
    my $packname = $gv->STASH->NAME;

    return $packname . "::" . $subname;
}

# Shamelessly lifted from Pod::Coverage, which it
# modifies as needed.
# this one walks the symbol tree
sub _get_syms {
    my $self    = shift;
    my $package = shift;

    print "requiring '$package'\n" if TRACE_ALL;
    eval qq{ require $package };
    if ($@) {
        print "require failed with $@\n" if TRACE_ALL;
        $self->{why_unrated} = "requiring '$package' failed";
        return;
    }

    print "walking symbols\n" if TRACE_ALL;
    my $syms = Devel::Symdump->new($package);

    my @symbols;
    for my $sym ( $syms->functions ) {

        # See if said method wasn't just imported *FROM ELSEWHERE*; --tchrist
        my $glob = do { no strict 'refs'; \*{$sym} };
        my $cv = B::svref_2object($glob);

        # in 5.005 this flag is not exposed via B, though it exists
        my $imported_cv = eval { B::GVf_IMPORTED_CV() } || 0x80;
        if ($cv->GvFLAGS & $imported_cv) {
            # Only count if as absolved via import if its name hasn't changed; --tchrist
            my $was_name = name_of_coderef(*{$glob}{CODE});
            next if join("::", $package, $sym) eq $was_name;
            my $his_pack = $was_name;
            $his_pack =~ s/::[^:]*$//;
            next if $package ne $his_pack;
        }

        # check if it's on the whitelist
        $sym =~ s/$self->{package}:://;
        next if $self->_private_check($sym);

        push @symbols, $sym;
    }
    return @symbols;
}

1;

__END__

=head1 NAME

Pod::Coverage::Careful - more careful subclass of Pod::Coverage

=head1 SYNOPSIS

 use Test::Pod::Coverage 1.08;
 use Pod::Coverage::Careful;

 pod_coverage_ok(
     "Some::Module",
     {
        coverage_class => "Pod::Coverage::Careful",
     },
     "improved pod coverage on Some::Module",
 );

=head1 DESCRIPTION

This module carefully subclasses L<Pod::Coverage> to override
its idea of which subs need to be documented.  This catches
several important cases that it misses.

The L<Pod::Coverage> module doesn't count subs that appear to be
imported as ones needing documentation. However, this also exempts
subs that were generated dynamically, such as:

    for my $color (qw(red blue green)) {
        no strict "refs";
        *$color = sub { print "I like $color.\n" };
    }

By supplying L<Test::Pod::Coverage/pod_coverage_ok> with
a C<coverage_class> of "Pod::Coverage::Careful", those
generated functions will now show up as in need of pod.

It also finds cases where subs are created by aliasing
an old one of a different name:

    *new_sub = \&old_sub;

This is true whether the alias is created form a sub in this
same package, or if you're importing one B<of a different name>.

One imports that are the same name as what they import are still
exempted from pod requirements.

=head1 BUGS AND RESTRICTIONS

None noted.

=head1 SEE ALSO

=over

=item L<Pod::Coverage>

Checks if the documentation of a module is comprehensive.

=item L<Test::Pod::Coverage>

Check for pod coverage in your distribution.

=back

=head1 AUTHOR

Tom Christiansen C<< <tchrist@perl.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2016, Tom Christiansen C<< <tchrist@perl.com> >>.
All Rights Reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


