#You should edit Tags_SiteConfig.pm instead of this file,
#which may be clobbered on module upgrade
Set($tagsRaw=>1);
Set($tagsComplete=>3);

1;
__END__

=pod

=head1 OPTIONS

You may configure RTX::Tags by setting variables in
F<local/etc/Tags_SiteConfig.pm>, or alternatively
F<local/plugins/RTx-Tags/etc/Tags_SiteConfig.pm>.

Recognized variables are:

=over

=item B<$tagsTypes>

Accepts an arrayref of object types to limit the count to.
By default RTx::Tags will count tags for any object in RT.

Of course, the links for each tag will only display corresponding I<tickets>.

=item B<$tagsLinkType>

If this is set to undef, tags are not linked to ticket search results.
This might be useful if your cloud features (many instances of) types
other than tickets.

=item B<$tagsStatus>

Accepts an arrayref of statuses to limit the count to,
with the side-effect of forcibly limiting B<$tagsTypes> to I<RT::Ticket>.

If you want to count tickets regardless of status you could use
C<$tagsTypes=E<gt>'RT::Ticket'>, but C<$tagsStatus=E<gt>undef>
is probably clearer.

A particularly handy incantantion is:

  #Only display 'Active' Tickets
  Set($tagsStatus=>\@RT::ActiveStatus);

=item B<$tagsRaw>

Enabled by default, a false setting will prevent the display of the
"Global" cloud on F<Search/TagCloud.html>. This cloud which provides
a view of the uncustomized cloud i.e; uses all of the defaults shown here.

=item B<$tagsComplete>

Minimum number of characters required before RTx::Tags returns possible
completions. The default is 3.

=back

=cut
