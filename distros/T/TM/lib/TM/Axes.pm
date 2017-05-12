package TM::Axes;

our $VERSION = '0.2';

=pod

=head1 NAME

TM::Axes - Topic Maps, Axes for TM::match*

=head1 DESCRIPTION

The L<TM> module offers the method C<match> (and friends) to query assertions in a TM data
structure. While there is a generic search specification, it will be too slow. Instead some axes
have been implemented specifically. These are listed below.

=head1 SEARCH SPECIFICATIONS

Automatically generated from TM (1.54)

=over

=item Code:<empty>

returns all assertions



=item Code:anyid

return all assertions where a given toplet appears somehow

          'anyid' => 'the toplet'

=item Code:aplayer.arole.bplayer.brole.type

return all assertions of a given type where a given toplet plays a given role and there exist another given role with another given toplet as player

          'bplayer' => 'the player for the brole',
          'aplayer' => 'the player toplet for the arole',
          'arole' => 'the role toplet (incl subclasses) for the aplayer',
          'type' => 'the type of the assertion',
          'brole' => 'the other role toplet (incl subclasses)'

=item Code:aplayer.arole.brole.type

return all assertions of a given type where a given toplet plays a given role and there exist another given role

          'aplayer' => 'the player toplet for the arole',
          'arole' => 'the role toplet (incl subclasses) for the aplayer',
          'type' => 'the type of the assertion',
          'brole' => 'the other role toplet (incl subclasses)'

=item Code:char.irole

deprecated: return all assertions which are characteristics for a given toplet

          'irole' => 'the toplet for which characteristics are sought',
          'char' => '1'

=item Code:char.topic

return all assertions which are characteristics for a given toplet

          'topic' => 'the toplet for which characteristics are sought',
          'char' => '1'

=item Code:char.topic.type

return all assertions which are a characteristic of a given type for a given topic

          'topic' => 'the toplet for which these characteristics are sought',
          'char' => '1',
          'type' => 'type of characteristic'

=item Code:char.type

return all assertions which are characteristics for some given type

          'char' => '1',
          'type' => 'the characteristic type'

=item Code:char.type.value

return all assertions which are characteristics for some topic of a given value for some given type

          'value' => 'the value for which all characteristics are sought',
          'char' => '1',
          'type' => 'the characteristic type'

=item Code:char.value

return all assertions which are characteristics for some topic of a given value

          'value' => 'the value for which all characteristics are sought',
          'char' => '1'

=item Code:class.type

returns all assertions where there are instances of a given toplet

          'class' => 'which toplet should be the class',
          'type' => 'isa'

=item Code:instance.type

returns all assertions where there are classes of a given toplet

          'type' => 'isa',
          'instance' => 'which toplet should be the instance'

=item Code:iplayer

return all assertions where a given toplet is a player

          'iplayer' => 'the player toplet'

=item Code:iplayer.irole

return all assertions where a given toplet is a player of a given role

          'iplayer' => 'the player toplet',
          'irole' => 'the role toplet (incl subclasses)'

=item Code:iplayer.irole.type

return all assertions of a given type where a given toplet is a player of a given role

          'iplayer' => 'the player toplet',
          'irole' => 'the role toplet (incl subclasses)',
          'type' => 'the type of the assertion'

=item Code:iplayer.type

return all assertions of a given type where a given toplet is a player

          'iplayer' => 'the player toplet',
          'type' => 'the type of the assertion'

=item Code:irole

return all assertions where there is a given role

          'irole' => 'the role toplet (incl subclasses)'

=item Code:irole.type

return all assertions of a given type where there is a given role

          'irole' => 'the role toplet (incl subclasses)',
          'type' => 'the type of the assertion'

=item Code:lid

return one particular assertions with a given ID

          'lid' => 'the ID of the assertion'

=item Code:nochar

returns all associations (so no names or occurrences)

          'nochar' => '1'

=item Code:subclass.type

returns all assertions where there are subclasses of a given toplet

          'subclass' => 'which toplet should be the superclass',
          'type' => 'is-subclass-of'

=item Code:superclass.type

returns all assertions where there are superclasses of a given toplet

          'superclass' => 'which toplet should be the subclass',
          'type' => 'is-subclass-of'

=item Code:type

return all assertions with a given type

          'type' => 'the type of the assertion'

=back


=head1 SEE ALSO

L<TM>

=head1 COPYRIGHT AND LICENSE

Copyright 200[8] by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

1;

