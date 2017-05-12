package Sub::Data::Recursive;
use strict;
use warnings FATAL => 'all';

our $VERSION = '0.01';

use Scalar::Util qw/refaddr/;

sub invoke {
    my ($class, $code, @args) = @_;
    _apply($code, +{}, @args);
}

sub _apply {
    my $code = shift;
    my $seen = shift;

    my @retval;
    for my $arg (@_) {
        if(my $ref = ref $arg){
            my $refaddr = refaddr($arg);
            my $proto;

            if(defined($proto = $seen->{$refaddr})){
                 # noop
            }
            elsif($ref eq 'ARRAY'){
                $proto = $seen->{$refaddr} = [];
                @{$proto} = _apply($code, $seen, @{$arg});
            }
            elsif($ref eq 'HASH'){
                $proto = $seen->{$refaddr} = {};
                %{$proto} = _apply($code, $seen, %{$arg});
            }
            elsif($ref eq 'REF' or $ref eq 'SCALAR'){
                $proto = $seen->{$refaddr} = \do{ my $scalar };
                ${$proto} = _apply($code, $seen, ${$arg});
            }
            else{ # CODE, GLOB, IO, LVALUE etc.
                $proto = $seen->{$refaddr} = $arg;
            }

            push @retval, $proto;
        }
        else{
            push @retval, defined($arg) ? $code->($arg) : $arg;
        }
    }

    return wantarray ? @retval : $retval[0];
}

1;

__END__

=head1 NAME

Sub::Data::Recursive - Recursive invoker


=head1 SYNOPSIS

    use Sub::Data::Recursive;
    use Data::Dumper;

    my $hash = +{
        bar => +{
            baz => 2
        },
        qux => 1,
    };

    Sub::Data::Recursive->invoke(
        sub { $_[0]++ },
        $hash,
    );

    print Dumper($hash);
    # $VAR1 = {
    #   'bar' => {
    #     'baz' => 3
    #   },
    #   'qux' => 2
    # };

=head1 DESCRIPTION

Sub::Data::Recursive is recursive invoker.


=head1 METHODS

=head2 invoke($code_ref, $hash [, $hash..])

invoke subroutine recursively


=head1 REPOSITORY

Sub::Data::Recursive is hosted on github
<http://github.com/bayashi/Sub-Data-Recursive>

Welcome your patches and issues :D


=head1 AUTHOR

Dai Okabayashi E<lt>bayashi@cpan.orgE<gt>


=head1 SEE ALSO

This module has forked from L<Data::Recursive::Encode>.


=head1 LICENSE

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.

=cut
