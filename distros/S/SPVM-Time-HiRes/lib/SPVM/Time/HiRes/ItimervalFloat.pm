package SPVM::Time::HiRes::ItimervalFloat;



1;

=head1 Name

SPVM::Time::HiRes::ItimervalFloat - Floating Point Representation of Sys::Time::Itimerval

=head1 Description

The Time::HiRes::ItimervalFloat class of L<SPVM> represents floating point representation of L<Sys::Time::Itimerval|SPVM::Sys::Time::Itimerval>.

=head1 Usage

  use Time::HiRes::ItimervalFloat;

=head1 Fields

=head2 it_interval

C<has it_interval : rw double;>

Gets and sets the C<it_interval> field.

=head2 it_value

C<has it_value : rw double;>

Gets and sets the C<it_interval> field.

=head1 Class Methods

C<static method new : L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat> ();>

Creates a new L<Time::HiRes::ItimervalFloat|SPVM::Time::HiRes::ItimervalFloat> object and returns it.

=head1 See Also

=over 2

=item * L<Time::HiRes|SPVM::Time::HiRes>

=back

=head1 Copyright & License

Copyright (c) 2023 Yuki Kimoto

MIT License

