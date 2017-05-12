package Parse::JCONF::Error;

use strict;
use overload '""' => \&to_string;

our $VERSION = '0.03';

sub new {
	my ($class, $msg) = @_;
	bless \$msg, $class;
}

sub throw {
	die $_[0];
}

sub to_string {
	my $self = shift;
	return $$self."\n";
}

package Parse::JCONF::Error::IO;
our @ISA = 'Parse::JCONF::Error';

package Parse::JCONF::Error::Parser;
our @ISA = 'Parse::JCONF::Error';

1;

__END__

=pod

=head1 NAME

Parse::JCONF::Error - errors representation for Parse::JCONF

=head1 SYNOPSIS

    use Parse::JCONF;
    
    eval {
        my $res = Parse::JCONF->new(autodie => 1)->parse("{}");
    };
    if (my $e = $@) {
        if (ref $e && $e->isa('Parse::JCONF::Error')) {
            warn "JCONF parser error: $e";
        }
    }

=head1 ERROR CLASSES

=head2 Parse::JCONF::Error

This is base error class.

=head3 Methods

=head4 Parse::JCONF::Error->new($msg)

Creates new error with message $msg

=head4 $error->throw()

Throws error

=head2 Parse::JCONF::Error::IO

Inherited from Parse::JCONF::Error. Represents I/O errors

=head2 Parse::JCONF::Error::Parser

Inherited from Parse::JCONF::Error. Represents parser errors

=head1 SEE ALSO

L<Parse::JCONF>

=head1 COPYRIGHT

Copyright Oleg G <oleg@cpan.org>.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
