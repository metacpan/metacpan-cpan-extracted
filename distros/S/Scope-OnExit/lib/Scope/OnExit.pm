package Scope::OnExit;
$Scope::OnExit::VERSION = '0.03';
use strict;
use warnings;
use Exporter 5.57 'import';
use XSLoader;

XSLoader::load(__PACKAGE__, __PACKAGE__->VERSION);

##no critic ProhibitAutomaticExportation
our @EXPORT = qw/on_scope_exit/;

1;    # End of Scope::OnExit

#ABSTRACT: DEPRECATED Running code on scope exit

__END__

=pod

=encoding UTF-8

=head1 NAME

Scope::OnExit - DEPRECATED Running code on scope exit

=head1 VERSION

version 0.03

=head1 SYNOPSIS

Execute code on scope exit

    use Scope::OnExit;

	{
	my $var = foo();
	on_scope_exit { do_something($var) };
	something_else();
	} # scope exit, do_something($var) is run now.

Note that Feature::Compat::Defer provides a much better way to do this. Unless you need compatibility with perls older than 5.14, I highly recommend using that instead.

=head1 FUNCTIONS

=head2 on_scope_exit { block }

This will make the block run at scope exit. 

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2009 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
