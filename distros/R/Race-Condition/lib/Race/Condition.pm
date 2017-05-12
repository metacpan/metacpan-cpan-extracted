package Race::Condition;

use strict;
use warnings;

$Race::Condition::VERSION = '0.01';

sub race::condition {    # no op by default
    return;
}

1;

__END__

=encoding utf-8

=head1 NAME

Race::Condition - Mark and make testable/debuggable known race conditions

=head1 VERSION

This document describes Race::Condition version 0.01

=head1 SYNOPSIS

    use Race::Condition (); # Knock Knock. Race::Condition. Who’s there?
    ⋮
    sub foo {
        my ($config) = @_;
        if (!-l $config && -f _ && -r _) {
            race::condition("config file could go away, change type, or become unreadable between file test and file read");
            open my $fh, '<', $config …
            ⋮
        }
    ⋮

Then in testing:

    {
        note "Testing foo() race condition when config file turns into symlink";
        
        my $name;
        no warnings "redefine";
        local *race::condition = sub {
            ($name) = $_[-1]; # use -1 so that it can be called as a method and/or have additional meta info if that made sense in your context
            ok(1, "sanity: race::condition() called ok for symlink test: $name");
            … change $temp_file symlink here …
        };
        
        … call foo() w/ $temp_file and test that is it handled as expected here …
        
        ok(defined $name, sanity: race::condition() called ok for symlink test: $name");
    }
    
    … ditto for deleted, changes to directory, changes to fifo, permission change, etc …

Or an FYI while debugging:

    no warnings "redefine";
    local *race::condition = sub {
        my ($race_text) = $_[-1]; # use -1 so that it can be called as a method and/or have addition meta info if that made sense in your context
        my $caller = [caller(0)];
        warn "Possible race condition “$race_text” in $caller->[1] line $caller->[2]\n";
    };
    ⋮
    …  foo() is called later …

=head1 DESCRIPTION

Often we mark race conditions that are not immediately solvable with a comment:

    if (!-l $config && -f _ && -r _) {
        # RACE! config file could go away, change type, or become unreadable between file test and file read
        open my $fh, '<', $config …
        …

That is good so that future us can be easily reminded of the issue. It is really hard/impossible to debug or test the various possible race conditions though.

This module gives us a way to still mark the race condition but also adds in the ability to hook into it for debugging or testing purposes.

    if (!-l $config && -f _ && -r _) {
        race::condition('config file could go away, change type, or become unreadable between file test and file read');
        open my $fh, '<', $config …
        …

=head1 INTERFACE 

By default race::condition() is a no–op. You can use it however you like; as a function, class method, or object method.

It is highly recommended to at least pass in a textual description of the race condition (as the last argument). 

Really, since you are defining the override and consuming it you can call it however you like.

However, if the text is always the last argument you can always refer to it via $_[-1] in your override which would make it more likely to be compatible with 3rdparty code.

=over 4

=item race::condition('textual description of race condition here')

=item Class->race::condition('textual description of race condition here')

=item $obj->race::condition('textual description of race condition here')

=item race::condition(@other_meta_info, 'textual description of race condition here')

    race::condition({ … }, 'textual description of race condition here');
    race::condition(__FILE__, __LINE__, 'textual description of race condition here');

=item Class->race::condition(@other_meta_info, 'textual description of race condition here)'

    Class->race::condition({ … }, 'textual description of race condition here');
    Class->race::condition(__FILE__, __LINE__, 'textual description of race condition here');

=item $obj->race::condition(@other_meta_info, 'textual description of race condition here')

    $obj->race::condition({ … }, 'textual description of race condition here');
    $obj->race::condition(__FILE__, __LINE__, 'textual description of race condition here');

=back

=head1 DIAGNOSTICS

Throws no errors or warnings of its own.

=head1 CONFIGURATION AND ENVIRONMENT

Race::Condition requires no configuration files or environment variables.

=head1 DEPENDENCIES

None.

=head1 INCOMPATIBILITIES

None reported.

=head1 BUGS AND LIMITATIONS

No bugs have been reported.

Please report any bugs or feature requests to
C<bug-race-condition@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.

=head1 AUTHOR

Daniel Muey  C<< <http://drmuey.com/cpan_contact.pl> >>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2014, Daniel Muey C<< <http://drmuey.com/cpan_contact.pl> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
