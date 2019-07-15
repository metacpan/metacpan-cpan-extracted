package Pcore::Lib::Perl;

use Pcore;

sub module {
    require Pcore::Lib::Perl::Module;

    return Pcore::Lib::Perl::Module->new(@_);
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Lib::Perl - perl code utils

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
