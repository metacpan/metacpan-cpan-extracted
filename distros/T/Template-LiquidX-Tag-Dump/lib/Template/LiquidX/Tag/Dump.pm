package Template::LiquidX::Tag::Dump;
our $VERSION = '1.0.6';
use Carp qw[confess];
use Template::Liquid;
use base 'Template::Liquid::Tag';
sub import { Template::Liquid::register_tag('dump') }

sub new {
    my ($class, $args, $tokens) = @_;
    confess 'Missing template' if !defined $args->{'template'};
    $args->{'attrs'} ||= '.';
    my $s = bless {name     => 'dump-' . $args->{'attrs'},
                   tag_name => $args->{'tag_name'},
                   variable => $args->{'attrs'},
                   template => $args->{'template'},
                   parent   => $args->{'parent'},
    }, $class;
    return $s;
}

sub render {
    my $s   = shift;
    my $var = $s->{'variable'};
    $var
        = $var eq '.'  ? $s->{template}{context}{scopes}
        : $var eq '.*' ? [$s->{template}{context}{scopes}]
        :                $s->{template}{context}->get($var);
    if (eval { require Data::Dump }) { # Better
        return Data::Dump::pp($var);
    }
    else { # CORE
        require Data::Dumper;
        return Data::Dumper::Dumper($var);
    }
    return '';
}
1;

=pod

=encoding utf-8

=head1 NAME

Template::LiquidX::Tag::Dump - Simple Perl Structure Dumping Tag (Functioning Custom Tag Example)

=head1 Synopsis

    use Template::Liquid;
    use Template::LiquidX::Tag::Dump;
    print Template::Liquid->parse("{%dump var%}")->render(var => [qw[some sort of data here]]);
	# With Data::Dump installed: ["some", "sort", "of", "data", "here"]

=head1 Description

This is a dead simple demonstration of
L<extending Template::Liquid|Template::Liquid/"Extending Template::Liquid">.

This tag attempts to use L<Data::Dump> and L<Data::Dumper> to create
stringified versions of data structures...

    use Template::Liquid;
    use Template::LiquidX::Tag::Dump;
    warn Template::Liquid->parse("{%dump env%}")->render(env => \%ENV);

...or the entire current scope with C<.>...

    use Template::Liquid;
    use Template::LiquidX::Tag::Dump;
    warn Template::Liquid->parse('{%dump .%}')
        ->render(env => \%ENV, inc => \@INC);

...or the entire stack of scopes with C<.*>...

    use Template::Liquid;
    use Template::LiquidX::Tag::Dump;
    warn Template::Liquid->parse('{%for x in (1..1) %}{%dump .*%}{%endfor%}')
        ->render();
        
...becomes (w/ Data::Dump installed)...

    do {
      my $a = [
        [
          {
            forloop => {
              first   => 1,
              index   => 1,
              index0  => 0,
              last    => 1,
              length  => 1,
              limit   => 1,
              name    => "x-(1..1)",
              offset  => 0,
              rindex  => 1,
              rindex0 => 0,
              sorted  => undef,
              type    => "ARRAY",
            },
            x => 1,
          },
          'fix',
        ],
      ];
      $a->[0][1] = $a->[0][0];
      $a;
    }

Notice even the internal C<forloop> variable is included in the dump.        

=head1 Notes

This is a 5m hack and is subject to change ...I've included no error handling
and it may be completly broken. For a better example, see
L<Template::LiquidX::Tag::Include>.

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
