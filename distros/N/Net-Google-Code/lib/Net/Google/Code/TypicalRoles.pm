package Net::Google::Code::TypicalRoles;
use Any::Moose 'Role';

with 'Net::Google::Code::Role::Fetchable';
with 'Net::Google::Code::Role::URL';
with 'Net::Google::Code::Role::HTMLTree';
with 'Net::Google::Code::Role::Authentication';
with 'Net::Google::Code::Role::Pageable';
with 'Net::Google::Code::Role::Predefined';

no Any::Moose;

1;

__END__

=head1 NAME

Net::Google::Code::TypicalRoles - TypicalRoles

=head1 DESCRIPTION

this is an aggregation of roles that includes the typical roles
for Code.pm, Code/Issue.pm, Code/Download.pm and Code/Wiki.pm

=head1 AUTHOR

sunnavy  C<< <sunnavy@bestpractical.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2008-2010 Best Practical Solutions.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


