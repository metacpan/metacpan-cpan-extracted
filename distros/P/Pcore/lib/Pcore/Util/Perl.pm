package Pcore::Util::Perl;

use Pcore;

sub module {
    require Pcore::Util::Perl::Module;

    return Pcore::Util::Perl::Module->new(@_);
}

1;
__END__
=pod

=encoding utf8

=head1 NAME

Pcore::Util::Perl - perl code utils

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 ATTRIBUTES

=head1 METHODS

=head1 SEE ALSO

=cut
