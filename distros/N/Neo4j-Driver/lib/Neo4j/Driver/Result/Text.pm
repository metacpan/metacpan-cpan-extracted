use 5.010;
use strict;
use warnings;
use utf8;

package Neo4j::Driver::Result::Text;
# ABSTRACT: Fallback handler for result errors
$Neo4j::Driver::Result::Text::VERSION = '0.27';

use parent 'Neo4j::Driver::Result';

use Carp qw(carp croak);
our @CARP_NOT = qw(Neo4j::Driver::Net::HTTP);


#our $ACCEPT_HEADER = "text/*; q=0.1";


sub new {
	my ($class, $params) = @_;
	
	my $header = $params->{http_header};
	my @errors = ();
	
	if (! $header->{success}) {
		my $reason_phrase = $params->{http_agent}->http_reason;
		push @errors, "HTTP error: $header->{status} $reason_phrase on $params->{http_method} to $params->{http_path}";
	}
	
	my $content_type = $header->{content_type};
	if ($content_type =~ m|^text/plain|) {
		push @errors, $params->{http_agent}->fetch_all;
	}
	else {
		push @errors, "Received " . ($content_type ? $content_type : "empty") . " content from database server; skipping result parsing";
	}
	
	croak join "\n", @errors if $params->{die_on_error};
	carp join "\n", @errors;
	
	return bless {}, $class;
}


sub _info { {} }  # no transaction status info => treat as closed


sub _results { () }  # no actual results provided here


# sub _accept_header { () }
# 
# 
# sub _acceptable {
# 	my ($class, $content_type) = @_;
# 	
# 	return $_[1] =~ m|^text/|i;
# }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Neo4j::Driver::Result::Text - Fallback handler for result errors

=head1 VERSION

version 0.27

=head1 DESCRIPTION

The L<Neo4j::Driver::Result::Text> package is not part of the
public L<Neo4j::Driver> API.

=head1 SEE ALSO

L<Neo4j::Driver::Net>

=head1 AUTHOR

Arne Johannessen <ajnn@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2016-2021 by Arne Johannessen.

This is free software, licensed under:

  The Artistic License 2.0 (GPL Compatible)

=cut
