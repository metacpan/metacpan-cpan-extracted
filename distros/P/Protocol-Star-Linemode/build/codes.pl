#!/usr/bin/env perl
# codes.pl - Generates the commands for bytes string
# Copyright (c) 2013 Peter Stuifzand
# Copyright (c) 2013 Other contributors as noted in the AUTHORS file
# 
# codes.pl is part of Protocol::Star::Linemode
# 
# Protocol::Star::Linemode is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of the License,
# or (at your option) any later version.
# 
# Protocol::Star::Linemode is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser
# General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

use Marpa::R2;
use File::Slurp 'read_file';
use Data::Dumper;

my $g = Marpa::R2::Scanless::G->new({
    action_object => 'main',
    default_action => 'do_first_arg',
    source         => \<<'SOURCE',

:start          ::= spec

spec            ::= <spec decl>+                              action => do_list

<spec decl>     ::= <prefix block>
                  | <spec rules>

<prefix block>  ::= 'prefix' hex_bytes <spec rules> 'end'     action => do_prefix_block
<spec rules>    ::= <spec rule>+                              action => do_list
<spec rule>     ::= name arg hex_bytes                        action => do_spec_rule

hex_bytes       ::= hex_byte+                                 action => do_list

hex_byte        ~ '0x' [0-9A-F] [0-9A-F]
name            ~ [\w]+
arg             ~ [\d]+


:discard        ~ ws
ws              ~ [\s]+
SOURCE

});

my $string = read_file('codes.spec');
my $r      = Marpa::R2::Scanless::R->new({ grammar => $g });

$r->read(\$string);

my $tree = ${$r->value};

my @rules;

for my $top_rule (@{ $tree }) {

    if (ref($top_rule) eq 'HASH' && $top_rule->{type} eq 'prefix_block') {
        for my $rule (@{$top_rule->{rules}}) {
            push @rules, {
                name  => $rule->{name},
                arg   => $rule->{arg},
                bytes => [ @{$top_rule->{prefix}}, @{$rule->{bytes}} ],
            };
        }
    }
    elsif (ref($top_rule) eq 'ARRAY') {
        push @rules, @$top_rule;
    }
}

print "# Generated file - do not modify\n";
print "# Copyright (c) 2013 Peter Stuifzand\n";
print "# Copyright (c) 2013 Other contributors as noted in the AUTHORS file\n";
print "#\n";
print "# Protocol::Star::Linemode::Generated is part of Protocol::Star::Linemode\n";
print "#\n";
print "# Protocol::Star::Linemode is free software; you can redistribute it and/or\n";
print "# modify it under the terms of the GNU Lesser General Public License as\n";
print "# published by the Free Software Foundation; either version 3 of the License,\n";
print "# or (at your option) any later version.\n";
print "#\n";
print "# Protocol::Star::Linemode is distributed in the hope that it will be useful,\n";
print "# but WITHOUT ANY WARRANTY; without even the implied warranty of\n";
print "# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser\n";
print "# General Public License for more details.\n";
print "#\n";
print "# You should have received a copy of the GNU Lesser General Public License\n";
print "# along with this program. If not, see <http://www.gnu.org/licenses/>.\n";

print "package Protocol::Star::Linemode::Generated;\n";
print "use Moo::Role;\n";

for my $rule (@rules) {
    my $name   = $rule->{name};
    my $nargs  = $rule->{arg};
    my @code   = @{$rule->{bytes}};

    my $bytes = join ", ", @code;
    my $args  = join ", ", (map { '$arg'.$_ } 0 .. ($nargs-1));

    my $len         = $nargs + scalar @code;
    my $pack_format = 'C' x $len;

    print <<"FUNC";
sub $name {
    my (\$self, $args) = \@_;
    \$self->append_pack("$pack_format", $bytes, $args);
    return;
}

FUNC

}

print "1;\n\n";

sub new {
    my $klass = shift;
    return bless {}, $klass;
}

sub do_first_arg {
    my $self = shift;
    return $_[0];
}

sub do_list {
    my $self = shift;
    return \@_;
}

sub do_prefix_block {
    my $self = shift;
    return { type => 'prefix_block', prefix => $_[1], rules => $_[2] };
}

sub do_spec_rule {
    my $self = shift;
    return { name => $_[0], arg => $_[1], bytes => $_[2] };
}

