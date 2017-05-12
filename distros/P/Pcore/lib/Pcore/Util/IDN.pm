package Pcore::Util::IDN;

use Pcore -export => [qw[domain_to_ascii domain_to_utf8]];

eval { require Net::LibIDN };

if ($@) {
    require Pcore::Util::IDN::PP;

    *domain_to_ascii = \&Pcore::Util::IDN::PP::domain_to_ascii;

    *domain_to_utf8 = \&Pcore::Util::IDN::PP::domain_to_utf8;
}
else {
    *domain_to_ascii = sub {
        return Net::LibIDN::idn_to_ascii( $_[0], 'utf-8' ) || die q[Can't convert IDN to ASCII];
    };

    *domain_to_utf8 = sub {
        my $str = Net::LibIDN::idn_to_unicode( $_[0], 'utf-8' ) || die q[Can't convert IDN to UTF-8];

        utf8::decode($str) or die q[Can't decode to UTF-8];

        return $str;
    };
}

1;
## -----SOURCE FILTER LOG BEGIN-----
##
## PerlCritic profile "pcore-script" policy violations:
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
## | Sev. | Lines                | Policy                                                                                                         |
## |======+======================+================================================================================================================|
## |    3 | 5                    | ErrorHandling::RequireCheckingReturnValueOfEval - Return value of eval not tested                              |
## +------+----------------------+----------------------------------------------------------------------------------------------------------------+
##
## -----SOURCE FILTER LOG END-----
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::IDN

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
