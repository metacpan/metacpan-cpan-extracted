package Pipe::Between::Object;

use 5.012001;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Pipe::Between::Object ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);

our $VERSION = '0.01';


# Preloaded methods go here.

sub new {
	my $class = shift;
	my $self = {
		data => [], 
	};
	return bless($self, $class);
}

sub count {
	my $self = shift;
	return 1 + $#{ $self->{data} };
}

sub push {
	my $self = shift;
	my $var = shift;
	push(@{ $self->{data} }, $var);
}

sub pull {
	my $self = shift;
	if(@{$self->{data}}) {
		return (shift(@{ $self->{data} }), 0);
	}
	else {
		return (undef, 1);
	}
}
	
1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Pipe::Between::Object - Pipe line between object

=head1 SYNOPSIS

  use Pipe::Between::Object;
  my $pipe = Pipe::Between::Object->new;

=head1 DESCRIPTION

This is a module provide pipe like object.
This is very simple module.

=head1 SEE ALSO

None.

=head1 AUTHOR

Pocket, E<lt>poketo7878@yahoo.co.jpE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Pocket

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.1 or,
at your option, any later version of Perl 5 you may have available.


=cut
