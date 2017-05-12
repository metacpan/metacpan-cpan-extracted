package Template::LiquidX::Tag::Include;
our $VERSION = '1.0.5';
use Template::Liquid;
require Template::Liquid::Error;
require Template::Liquid::Utility;
use File::Spec;
use base 'Template::Liquid::Tag';
my $base_dir;

sub import {
    $base_dir = $_[1] ? $_[1] : '_includes/';
    Template::Liquid::register_tag('include');
}

sub new {
    my ($class, $args) = @_;
    raise Template::Liquid::Error {type    => 'Context',
                                   message => 'Missing template argument',
                                   fatal   => 1
        }
        if !defined $args->{'template'};
    raise Template::Liquid::Error {type    => 'Context',
                                   message => 'Missing parent argument',
                                   fatal   => 1
        }
        if !defined $args->{'parent'};
    raise Template::Liquid::Error {
                   type    => 'Syntax',
                   message => 'Missing argument list in ' . $args->{'markup'},
                   fatal   => 1
        }
        if !defined $args->{'attrs'};
    return
        bless {name     => 'inc-' . $args->{'attrs'},
               file     => $args->{'attrs'},
               parent   => $args->{'parent'},
               template => $args->{'template'},
               tag_name => $args->{'tag_name'},
               markup   => $args->{'markup'},
        }, $class;
}

sub render {
    my ($s) = @_;
    my $file = $s->{template}{context}->get($s->{'file'});
    raise Template::Liquid::Error {
           type    => 'Argument',
           message => 'Error: Missing or undefined argument passed to include'
        }
        && return
        if !defined $file;
    if (   $file !~ m[^[\w\\/\.-_]+$]io
        || $file =~ m[\.[\\/]]o
        || $file =~ m[[//\\]\.]o)
    {   raise Template::Liquid::Error {
        type => 'Argument',
        message => sprintf
            q[Error: Include file '%s' contains invalid characters or sequiences],
            $file} && return;
    }
    $file = File::Spec->catdir(

        # $s->{template}{context}->registers->{'site'}->source,
        $base_dir,
        $file
    );
    raise Template::Liquid::Error {
                       type    => 'I/O',
                       message => sprintf 'Error: Included file %s not found',
                       $file
        }
        && return
        if !-f $file;
    open(my ($FH), '<', $file)
        || raise Template::Liquid::Error {
                       type    => 'I/O',
                       message => sprintf 'Error: Cannot include file %s: %s',
                       $file, $!
        }
        && return;
    sysread($FH, my ($DATA), -s $FH) == -s $FH
        || raise Template::Liquid::Error {
            type    => 'I/O',
            message => sprintf
                'Error: Cannot include file %s (Failed to read %d bytes): %s',
            $file, -s $FH, $!
        }
        && return;
    my $partial = Template::Liquid->parse($DATA);
    $partial->{'context'} = $s->{template}{context};
    my $return = $partial->{context}->stack(sub { $partial->render(); });
    return $return;
}
1;

=pod

=head1 NAME

Template::LiquidX::Tag::Include - Include another file (Functioning Custom Tag Example)

=head1 Synopsis
	
    {% include 'comments.inc' %}

=head1 Description

This is a demonstration of
L<extending Template::Liquid|Template::Liquid/"Extending Template::Liquid">.

If you find yourself using the same snippet of code or text in several
templates, you may consider making the snippet an include.

You include static filenames...

    use Template::Liquid;
    use Template::LiquidX::Tag::Include;
    Template::Liquid->parse("{%include 'my.inc'%}")->render();

...or 'dynamic' filenames (for example, based on a variable)...

    use Template::Liquid;
    use Template::LiquidX::Tag::Include;
    Template::Liquid->parse('{%include inc%}')->render(inc => 'my.inc');

=head1 Notes

The default directory searched for includes is C<./_includes/> but this can be
changed in the include statement...

    use Template::LiquidX::Tag::Include '~/my_site/templates/includes';

This mimics Jekyll's include statement and was a 15m hack so it's subject to
change ...and may be completly broken.

=head1 See Also

Liquid for Designers: http://wiki.github.com/tobi/liquid/liquid-for-designers

L<Template::Liquid|Template::Liquid/"Extending Template::Liquid">'s section on
custom tags.

=head1 Author

Sanko Robinson <sanko@cpan.org> - http://sankorobinson.com/

=head1 License and Legal

Copyright (C) 2009-2016 by Sanko Robinson E<lt>sanko@cpan.orgE<gt>

This program is free software; you can redistribute it and/or modify it under
the terms of The Artistic License 2.0.  See the F<LICENSE> file included with
this distribution or http://www.perlfoundation.org/artistic_license_2_0.  For
clarification, see http://www.perlfoundation.org/artistic_2_0_notes.

When separated from the distribution, all original POD documentation is
covered by the Creative Commons Attribution-Share Alike 3.0 License.  See
http://creativecommons.org/licenses/by-sa/3.0/us/legalcode.  For
clarification, see http://creativecommons.org/licenses/by-sa/3.0/us/.

=cut
