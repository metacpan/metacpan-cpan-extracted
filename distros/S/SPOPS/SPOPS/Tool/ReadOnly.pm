package SPOPS::Tool::ReadOnly;

# $Id: ReadOnly.pm,v 3.3 2004/06/02 00:48:24 lachoy Exp $

use strict;
use Log::Log4perl qw( get_logger );
use SPOPS;
use SPOPS::ClassFactory qw( OK );

my $log = get_logger();

$SPOPS::Tool::ReadOnly::VERSION = sprintf("%d.%02d", q$Revision: 3.3 $ =~ /(\d+)\.(\d+)/);

sub behavior_factory {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Installing read-only persistence methods for ($class)" );
    return { read_code => \&generate_persistence_methods };
}

sub generate_persistence_methods {
    my ( $class ) = @_;
    $log->is_info &&
        $log->info( "Generating read-only save() and remove() for ($class)" );
    no strict 'refs';
    *{ "${class}::save" }   =
        sub {
            SPOPS::Exception->throw( ref $_[0], " is read-only; no changes allowed" );
        };
    *{ "${class}::remove" } =
        sub {
            SPOPS::Exception->throw( ref $_[0], " is read-only; no changes allowed" );
        };
    return OK;
}

1;

__END__

=head1 NAME

SPOPS::Tool::ReadOnly - Make a particular object read-only

=head1 SYNOPSIS

 # Load information with read-only rule

 my $spops = {
    class               => 'This::Class',
    isa                 => [ 'SPOPS::DBI' ],
    field               => [ 'email', 'language', 'country' ],
    id_field            => 'email',
    base_table          => 'test_table',
    rules_from          => [ 'SPOPS::Tool::ReadOnly' ],
 };
 SPOPS::Initialize->process({ config => { test => $spops } });

 # Fetch an object, modify it... 
 my $object = This::Class->fetch( 45 );
 $object->{foo} = "modification";

 # Trying to save the object throws an error:
 # "This::Class is read-only; no changes allowed"
 eval { $object->save };

=head1 DESCRIPTION

This is a simple rule to ensure that C<save()> and C<remove()> calls
to a particular class do not actually do any work. Instead they just
result in a warning that the class is read-only.

=head1 METHODS

B<behavior_factory()>

Installs the behavior during the class generation process.

B<generate_persistence_methods()>

Generates C<save()> and C<remove()> methods that just throw
exceptions.

=head1 BUGS

None known.

=head1 TO DO

Nothing known.

=head1 SEE ALSO

L<SPOPS::Manual::ObjectRules|SPOPS::Manual::ObjectRules>

L<SPOPS::ClassFactory|SPOPS::ClassFactory>

=head1 COPYRIGHT

Copyright (c) 2001-2004 intes.net, inc.. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Chris Winters E<lt>chris@cwinters.comE<gt>
