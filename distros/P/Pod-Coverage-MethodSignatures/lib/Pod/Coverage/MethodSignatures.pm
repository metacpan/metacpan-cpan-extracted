package Pod::Coverage::MethodSignatures;

=head1 NAME

Pod::Coverage::MethodSignatures - L<Pod::Coverage> extension for L<Method::Signatures>

=head1 SYNOPSIS

  use Pod::Coverage::MethodSignatures;

  my $pcm = Pod::Coverage::MethodSignatures->new(package => 'Foo::Bar');
  print 'Coverage: ', $pcm->coverage, "\n";

  # or in a pod-coverage.t

  use Test::More;
  eval "use Test::Pod::Coverage 1.00";
  plan skip_all => "Test::Pod::Coverage 1.00 required for testing POD coverage" if $@;
  all_pod_coverage_ok({ coverage_class => 'Pod::Coverage::MethodSignatures'});

=head1 DESCRIPTION

This module works exactly as L<Pod::Coverage> does, but with a more chill
approach to verifying code origin, as overridden in _get_syms(), and with
whitelisting of func() and method(), as overridden in _trustme_check().

See the documentation for L<Pod::Coverage> for more information on usage.

This module might also support other things such as L<MooseX::Declare> and
L<MooseX::Method::Signatures> but I haven't tested that.

=cut

our $VERSION = "0.02";

use base Pod::Coverage;

BEGIN { defined &TRACE_ALL or eval 'sub TRACE_ALL () { 0 }' }

sub _get_syms {
    my $self    = shift;
    my $package = shift;

    print "requiring '$package'\n" if TRACE_ALL;
    eval qq{ require $package };
    print "require failed with $@\n" if TRACE_ALL and $@;
    return if $@;

    print "walking symbols\n" if TRACE_ALL;
    my $syms = Devel::Symdump->new($package);

    my @symbols;
    for my $sym ( $syms->functions ) {

        # see if said method wasn't just imported from elsewhere
        # using some pre-Pod::Coverage-0.18 code
        my $b_cv = B::svref_2object(\&{ $sym });
        print "checking origin package for '$sym':\n",
            "\t", $b_cv->GV->STASH->NAME, "\n" if TRACE_ALL;
        next unless $b_cv->GV->STASH->NAME eq $self->{'package'};

        # check if it's on the whitelist
        $sym =~ s/$self->{package}:://;
        next if $self->_private_check($sym);

        push @symbols, $sym;
    }
    return @symbols;
}

sub _trustme_check {
    my ($self, $sym) = @_;
    return (grep { $sym eq $_ } (qw/func method/))
        || $self->SUPER::_trustme_check(@_);
    
}

1;

=head1 SEE ALSO

L<Method::Signatures>,
L<Pod::Coverage>,
L<Test::Pod::Coverage>

=head1 THANKS

L<Pod::Coverage::Moose> authors - for the borrowed Pod

Michael Schwern - for the answered questions and verified hypotheses

=head1 AUTHOR

Darian Anthony Patrick E<lt>dap@darianpatrick.comE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
