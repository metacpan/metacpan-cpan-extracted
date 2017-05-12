package Parse::JCONF::Boolean;

use strict;
use Scalar::Util 'refaddr';
use overload
	'""' => sub { ${$_[0]} },
	'==' => sub { refaddr $_[0] == refaddr $_[1] },
	fallback => 1;

use constant {
	TRUE  => bless(\(my $true  = 1),  __PACKAGE__),
	FALSE => bless(\(my $false = ''), __PACKAGE__)
};

our $VERSION = '0.03';

use parent 'Exporter';
our @EXPORT_OK = qw(TRUE FALSE);

1;

__END__

=pod

=head1 NAME

Parse::JCONF::Boolean - boolean constants for Parse::JCONF

=head1 SYNOPSIS

    use Parse::JCONF;
    use Parse::JCONF::Boolean qw(TRUE FALSE);
    
    my $res = Parse::JCONF->new(autodie => 1)->parse_file('/dev/random');
    if ($res->{bool_value} == TRUE) {
        print "this is boolean true";
    }
    elsif ($res->{bool_value} == FALSE) {
        print "this is boolean false";
    }

=head1 DESCRIPTION

This package provides two constants: TRUE and FALSE. This constants may be exported on request.
You can compare value parsed by JCONF parser with this constants to determine that value is of boolean
type (was true/false in JCONF).

=head1 SEE ALSO

L<Parse::JCONF>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
