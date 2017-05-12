package Module::JSAN::DSL;

use strict;
use vars qw{$VERSION @ISA};

BEGIN {
	$VERSION = '0.03';
	
	require Module::Build::Functions::DSL;
	
	@ISA = 'Module::Build::Functions::DSL';
	
	*inc::Module::JSAN::DSL::VERSION = *VERSION;
	@inc::Module::JSAN::DSL::ISA     = __PACKAGE__;
}


sub get_header_code {
    
    # Load inc::Module::JSAN as we would in a regular Makefile.Pl    
    return <<END_OF_CODE;
package main;

use inc::Module::JSAN;
END_OF_CODE
        
}

__PACKAGE__;

__END__

=pod

=head1 NAME

inc::Module::JSAN::DSL - Domain Specific Language for Module::JSAN

=head1 SYNOPSIS

    use inc::Module::JSAN::DSL;
    
    
    name            Digest.MD5
        
    version         0.01
        
    author          'SamuraiJack <root@symbie.org>'
    abstract        'JavaScript implementation of MD5 hashing algorithm'
        
    license         perl
        
    requires        Cool.JS.Lib             1.1
    requires        Another.Cool.JS.Lib     1.2
    
    
    build_requires  Building.JS.Lib         1.1
    build_requires  Another.Building.JS.Lib 1.2

=head1 DESCRIPTION

One of the primary design goals of L<Module::JSAN> is to simplify
the creation of F<Build.PL> scripts.

Part of this involves the gradual reduction of any and all superflous
characters, with the ultimate goal of requiring no non-critical
information in the file.

L<Module::JSAN::DSL> is a simple B<Domain Specific Language> based
on the already-lightweight L<Module::Install> command syntax.

The DSL takes one command on each line, and then wraps the command
(and its parameters) with the normal quotes and semi-colons etc to
turn it into Perl code.

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Module-JSAN>

For other issues contact the author.

=head1 AUTHORS

Nickolay Platonov, C<< <nplatonov at cpan.org> >>


=head1 ACKNOWLEDGEMENTS

Many thanks to Module::Install authors, on top of which this module is mostly based.

=head1 COPYRIGHT

Copyright 2009 Nickolay Platonov.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
