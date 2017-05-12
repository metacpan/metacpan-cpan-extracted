package OpenPlugin::Exception::Template;

# $Id: Template.pm,v 1.2 2003/04/28 17:49:47 andreychek Exp $

use strict;
use base qw( OpenPlugin::Exception );

$OpenPlugin::Exception::Template::VERSION   = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/);

# These are the additional fields/parameters we're looking to provide in our
# Exception Plugin subclass.  For example, if this were called
# OpenPlugin::Exception::DBI, perhaps one of the fields below would be called
# "sql", which could hold the SQL statement that was being used when the
# exception occurred.
my @FIELDS = qw( field1 field2 field3 );

# This sub overrides the get_fields sub in the parent class, and simply returns
# all the fields this subclass uses
sub get_fields {
    return ( $_[0]->SUPER::get_fields, @FIELDS );
}

__END__

=pod

=head1 NAME

OpenPlugin::Exception::Template - Sample template for creating Exception Plugin drivers.

=head1 DESCRIPTION

This is a template for creating additional Exception drivers (subclasses).
Most people do this to provide additional fields for certain types of
exceptions.  Exceptions which occur in the Datasource Plugin might contain a
field called C<sql>, for capturing the SQL statement which was used when the
exception occurred.

Of course, if you add a new Exception plugin, you'll need to add it to both the OpenPlugin-drivermap.conf and OpenPlugin.conf files.

Adding this driver to OpenPlugin-drivermap.conf would look like:

 <drivermap exception>
    built-in = OpenPlugin::Exception
    template = OpenPlugin::Exception::Template
 </drivermap>

And you'd do the following to add this to the OpenPlugin.conf file:

 <plugin exception>
     load    = Startup

     <driver built-in>
     </driver>

     <driver template>
     </driver>

 </plugin>

=head1 PARAMETERS

No parameters can be passed in to OpenPlugin's B<new()> method for this driver.
The following parameters are accepted via the B<throw()> and B<log_throw()>
methods:

=over 4

=item * field1

This example field would contain data of your choice.

=item * field2

This example field would contain data of your choice.

=item * field3

This example field would contain data of your choice.

=back

=head1 TO DO

Nothing known.

=head1 BUGS

None known.

=head1 COPYRIGHT

Copyright (c) 2001-2003 Eric Andreychek. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHORS

Eric Andreychek <eric@openthought.net>

=cut


1;
