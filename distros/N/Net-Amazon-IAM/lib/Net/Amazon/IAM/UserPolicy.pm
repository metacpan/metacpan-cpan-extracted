package Net::Amazon::IAM::UserPolicy;
use Moose;

has 'PolicyName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'PolicyDocument' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

has 'UserName' => (
   is       => 'ro',
   isa      => 'Str',
   required => 0,
);

__PACKAGE__->meta->make_immutable();

=head1 AUTHOR

Igor Tsigankov <tsiganenok@gmail.com>

=head1 COPYRIGHT

Copyright (c) 2015 Igor Tsigankov . This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

no Moose;
1;
