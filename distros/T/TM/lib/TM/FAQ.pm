package TM::FAQ;

=pod

=head1 NAME

TM::FAQ - Topic Maps, Frequently Angering Quirks

=head1 FAQ, TIPS AND PITFALLS

=over

=item

Q: I am using MLDBM as persistent store and the larger the map grows the MUCH slower insertions
become.

A: The way MLDBM works is that at every access (read or write) a large portion of the map is
loaded via DBM into memory (and written back). One option is to avoid needpin-like modifications
and to exploit the fact that many routines accept lists as parameters.

So DO NOT do this:

   for some changes {
       $tm->assert ( one change );
   }   

But DO that:

   $tm->assert (
        map { one change $_ } some changes
   );

Similar with topic changes.

Another option is to use a second, in-memory map for additions and then C<add> the modifications
to the MLDBM based map:

   my $updates = new TM;
   $updates->internalize ....
   $updates->assert ....

   $dbm->add ($updates);

=item

Q: I am using MLDBM as persistent store and receive very strange errors which indicate that
the map is empty.

A: You could be dealing with a sitation that the DBM file already exists, but is completely
empty (maybe because tmpnam created it). This has been fixed in v1.54.

=item

Q: How can I get rid of these annoying topics C<occurrence>, C<name>, etc. which I have not put into
the map in the first place. They seem to be in each map I create.

A: These infrastructure topics are needed to make the map I<complete> (everything used is
defined). Per se, you cannot remove them and, seriously you probably do not want that to happen.

But you can filter these out when you retrieve a list of toplets:

   my @ts   = $tm->toplets (\ '+all -infrastructure');

=item

Q: How can I get all names and/or occurrences of a topic?

A: If you have a topic identifier C<mytopic> in your hand, then you can get all characteristics (=
names and occurrences, but not associations) with

    my @cs = $tm->match_forall (char => 1, irole => $tm->tids ('mytopic'));

Then you can filter occording the type, the scope, the data type value or the C<KIND>. The latter
tells you whether an assertion is a name or occurrence. For example those occurrences which are
C<occurrence>s and not anything specials as, say, C<homepage>:

    my @occs  = map  { $_->[0] } 
                map  { TM::get_x_players ($tm, $_, 'value') }
                grep { $_->[TM->TYPE] eq 'occurrence' } @cs;

=item

Q: Some of these maps I create have the trait C<ResourceAble> and import therefore a method
C<mtime>. How does this work?

A: Every map which is attached to an external resource is said to be I<resourceable>, hence the
trait with the same name. You, the developer, decide which copy of the map is the I<authoritative>,
i.e. what should happen should the map infrastructure be forced to synchronize the content.

While the synchronization (and when that is triggered) is handled by the trait
L<TM::Synchronizable>, the infrastructure needs to know (a) when the in-memory copy of the map was
last modified and (b) when the resource to which it is attached has been modified last. This is the
reasons for timestamps on the memory-stored map.

The resources themselves also have these timestamps; when the resource is a file on a file system,
then the "last modified" timestamps are take from there. The only complication is that L<TM> is
using a much higher time resolution as most file systems (L<HiRes::Time>).

=item

Q: When using AsTMa (1.x) it is very difficult to figure out where I make a syntax error. Is
there a convenient and effective way? What about line numbers?

A: One approach is to use the C<%cancel> method: When added to the file, the parser will stop there
and write a message onto STDERR. Another method is to use C<%trace 1> within the AsTMa stream. Then
the parser should let you know what it could detect successfully.

Line numbers cannot be used because the file will be massively reduced before the parser actually
sees it.

=item

Q: When serializing large maps, the serializer is REALLY slow. How to make it faster?

A: The problem was that some serializers have to call the method C<is_reified> very often to
find out whether there is a reification for the assertion. If this becomes a concern to you, simply
add an index over reification (available since 1.53):

   use Class::Trait;
   Class::Trait->apply ($tm, 'TM::Serializable::XTM');

   use TM::Index::Reified;
   my $idx = new TM::Index::Reified ($tm, closed => 1);

   print $tm->serialize;

=back

=head1 COPYRIGHT AND LICENSE

Copyright 20(0[3-68]|10) by Robert Barta, E<lt>drrho@cpan.orgE<gt>

This library is free software; you can redistribute it and/or modify it under the same terms as Perl
itself.

=cut

our $VERSION  = 0.8;

1;
