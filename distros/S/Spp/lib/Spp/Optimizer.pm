package Spp::Optimizer;

=head1 NAME

Spp::Optimizer - Optimizer of match data

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.02';


=head1 SYNOPSIS

Optimizer the match data structure to AST of Spp

    use Spp::Optimizer qw(opt_atom);

    my $ast = opt_atom(match_rule($str, $rule));

=head1 EXPORT

opt_atom

=cut

use Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(opt_atom);

use 5.020;
use Carp qw(croak);
use experimental qw(switch autoderef);

use Spp::Tools;

#######################
# Optimizer Ast
#######################

sub opt_str_char {
  my $value = shift;
  my $char = substr($value, -1);
  given ($char) {
    when ('n') { return "\n" }
    when ('r') { return "\r" }
    when ('t') { return "\t" }
    default { return $char }
  }
}

sub combin_str_nodes {
  my $nodes = shift;
  my $str_nodes = [];
  my ($str, $str_mode) = ('', 0);
  for my $node (values $nodes) {
    if ($node->[0] eq 'str') {
      $str = $str . $node->[1];
      $str_mode = 1;
    }
    else {
      if ($str_mode == 1) {
        push $str_nodes, ['str', $str];
      }
      push $str_nodes, $node;
      $str = '';
      $str_mode = 0;
    }
  }
  if ($str_mode == 1) {
    push $str_nodes, ['str', $str];
  }
  return $str_nodes;
}

sub delete_branch {
  my $ast = shift;
  my $ast_len = len($ast);
  my ($index, $flag_pass) = (0, 0);
  my $atoms = [];
  while ($index < $ast_len) {
    my $atom = $ast->[$index];
    $index++;
    if (in($atom->[0], ['lbranch', 'branch'])) {
      if ($flag_pass == 1 and $index < $ast_len) {
        $flag_pass = 0;
        push $atoms, $atom;
      }
    }
    else {
      $flag_pass = 1;
      push $atoms, $atom;
    }
  }
  return $atoms;
}

sub gather_branch {
  # see [@_];
  my ($atoms, $branch_atom) = @_;
  my $branch = [];
  my $flag = 0;
  my $opt_atoms = [];
  for my $atom (values $atoms) {
    # see $atom;
    if (is_same($atom, $branch_atom)) {
      push $opt_atoms, $branch;
      $branch = [];
      $flag = 0;
    } else {
      push $branch, $atom;
      $flag = 1;
    }
  }
  push $opt_atoms, $branch if $flag == 1;
  # see $opt_atoms;
  return $opt_atoms;
}

sub opt_atoms {
  my $atoms = shift;
  my $atoms_opt = [];
  for my $atom (values $atoms) {
    push $atoms_opt, opt_atom($atom);
  }
  return $atoms_opt;
}

sub opt_exprs {
  my $atoms = shift;
  my $atoms_opt = opt_atoms($atoms);
  return add_exprs($atoms_opt);
}

sub opt_atom {
  my $atom = shift;
  return ['bool','true'] if $atom eq '{}';
  # see $atom;
  my ($type, $value) = @{$atom};
  # see $name; exit;
  return opt_exprs($atom) if is_array($type);
  given ($type) {
    when ('sym')     { opt_sym($value)    }
    when ('char')    { opt_char($value)   }
    when ('Str')     { opt_str($value)    }
    when ('Keyword') { opt_str($value)    }
    when ('String')  { opt_string($value) }
    when ('Sarray')  { opt_sarray($value) }
    when ('List')    { opt_list($value)   }
    when ('Array')   { opt_array($value)  }
    when ('Hash')    { opt_hash($value)   }
    when ('Pair')    { opt_atoms($value)  }
    when ('Rule')    { opt_rule($value)   }
    when ('Group')   { opt_group($value)  }
    when ('Strs')    { opt_strs($value)   }
    when ('Chclass') { opt_chclass($value)}
    when ('Action')  { opt_atom($value)   }
    when ('Alias')   { opt_alias($value)  }
    when ('chars')   { ['str', $value]    }
    when ('int')     { ['int', $value+0]  }
    when ('any')     { ['any', '.']       }
    when ('dot')     { ['dot', '.']       }
    when ('ctoken')  { ['ctoken', $value] }
    when ('rtoken')  { ['rtoken', $value] }
    when ('gtoken')  { ['gtoken', $value] }
    when ('assert')  { ['assert', $value] }
    when ('cclass')  { ['cclass', $value] }
    # if String only have blank interlatation
    when ('inter')   { ['str', '']        }
    see $atom;
    default { error("Unknown type: $type to optimizer") }
  }
}

sub opt_sym {
  my ($value, $at) = @_;
  given ($value) {
    when ('nil')   { return ['nil', 'nil']   }
    when ('true')  { return ['bool', 'true']  }
    when ('false') { return ['bool', 'false'] }
    default        { return ['sym', $value]   }
  }
}

sub opt_char {
  my ($value) = @_;
  my $opt_char = opt_str_char($value);
  return ['str', $opt_char];
}

sub opt_str {
  my ($nodes) = @_;
  return ['str', ''] if $nodes eq "''";
  my $chars = [];
  for my $node (values $nodes) {
    my ($type, $value) = @{$node};
    given ($type) {
      when ('char') { push $chars, opt_str_char($value) }
      default { push $chars, $value }
    }
  }
  return ['str', host_join($chars)];
}

sub opt_string {
  my ($ast) = @_;
  return '' if $ast eq '""';
  my $nodes = [];
  for my $node (values $ast) {
    my ($type, $value) = @{$node};
    given ($type) {
      when ('char') {
        my $char_str = opt_str_char($value);
        push $nodes, ['str', $char_str];
      }
      when ('dstr') { push $nodes, ['str', $value] }
      default { push $nodes, opt_atom($node) }
    }
  }
  my $str_nodes = combin_str_nodes($nodes);
  if (len($str_nodes) == 1 and $nodes->[0][0] eq 'sym') {
    return $str_nodes->[0];
  }
  return ['string', $str_nodes];
}

sub opt_sarray {
  my $ast = shift;
  my $strs = [];
  my $str = '';
  for my $node (values $ast) {
    my ($type, $value) = @{ $node };
    given ($type) {
      when ('cstr') { $str = $str . $value }
      when ('char') { $str = $str . opt_str_char($value) }
      when ('blank') {
        push $strs, ['str', $str] if len($str) > 0;
        $str = '';
      }
      default { error("Unknown Aarray node type: $type") }
    }
  }
  push $strs, ['str', $str] if len($str) > 0;
  return ['array', $strs];
}

sub opt_hash {
  my ($hash) = @_;
  # hash would saved as array to contain keys value
  return ['hash', []] if $hash eq '{}';
  my $hash_opt = [];
  for my $pair (values $hash) {
    if ($pair->[0] eq 'Pair') {
      my $pair_value = $pair->[1];
      my $opt_pair = opt_atoms($pair_value);
      push $hash_opt, $opt_pair;
    } else {
      error("Hash key name not is <Pair>");
    }
  }
  return ['hash', $hash_opt];
}

sub opt_list {
  my ($atoms) = @_;
  return ['list', []] if $atoms eq '()';
  my $atoms_opt = opt_atoms($atoms);
  return ['list', $atoms_opt];
}

sub opt_array {
  my ($atoms) = @_;
  return ['array', []] if $atoms eq '[]';
  my $atoms_opt = opt_atoms($atoms);
  return ['array', $atoms_opt];
}

sub opt_rule {
  my ($atoms) = @_;
  return ['bool','true'] if $atoms eq ':{}';
  my $rule_value = opt_token($atoms);
  return ['rule', $rule_value];
}

sub opt_group {
  my ($ast) = @_;
  return ['bool','true'] if $ast eq '()';
  my $atoms = opt_token_atoms($ast);
  if (in($atoms->[0], ['lbranch', 'branch'])) {
    return $atoms;
  }
  return ['group', $atoms];
}

sub opt_token {
  my $args = shift;
  my $atoms = opt_token_atoms($args);
  if (in($atoms->[0], ['lbranch', 'branch'])) {
    return $atoms;
  }
  return $atoms->[0] if len($atoms) == 1;
  return ['token', $atoms];
}

sub opt_token_atoms {
  my $atoms = shift;
  $atoms = delete_branch($atoms);
  my $lb_flag = ['lbranch','|'];
  if (in($lb_flag, $atoms)) {
    my $branch = gather_branch($atoms, $lb_flag);
    return opt_lbranch($branch);
  }
  my $b_flag = ['branch', '||'];
  if (in($b_flag, $atoms)) {
    my $branch = gather_branch($atoms, $b_flag);
    my $opt_branch = opt_branch($branch);
    return $opt_branch;
  }
  my ($index, $opt_atoms) = (0, []);
  while ($index < len($atoms)) {
    my $look = next_atom_is_look($atoms, $index);
    my $rept = next_atom_is_rept($atoms, $index);
    if ($look) {
      push $opt_atoms, $look;
      $index += 3;
    } elsif ($rept) {
      push $opt_atoms, $rept;
      $index += 2;
    } else {
      my $atom = $atoms->[$index];
      push $opt_atoms, opt_atom($atom);
      $index += 1;
    }
  }
  return $opt_atoms;
}

sub opt_lbranch {
   my ($ast) = @_;
   my $atoms = [];
   for my $branch (values $ast) {
     push $atoms, opt_token($branch);
   }
   return ['lbranch', $atoms];
}

sub opt_branch {
   my ($ast) = @_;
   my $atoms   = [];
   for my $branch (values $ast) {
     push $atoms, opt_token($branch);
   }
   return ['branch', $atoms];
}

sub next_atom_is_rept {
   my ( $atoms, $atom_pos ) = @_;
   if ( $atom_pos < len($atoms) - 1 ) {
      my $next_atom = $atoms->[ $atom_pos + 1 ];
      if ( $next_atom->[0] eq 'rept' ) {
        my $atom = @{$atoms}[$atom_pos];
        my $atom_opt = opt_atom($atom);
        my $rept_opt = opt_rept($next_atom->[1]);
        return ['rept', [$atom_opt, $rept_opt]];
      }
   }
   return 0;
}

sub next_atom_is_look {
   my ( $atoms, $index ) = @_;
   return 0 if $index >= len($atoms) - 1;
   my $next_atom = $atoms->[$index+1];
   return 0 if $next_atom->[0] ne 'look';
   my $first_atom = $atoms->[$index];
   if (($index + 2) >= len($atoms)) {
     error("look atom missed");
   }
   my $look_atom = $atoms->[ $index + 2 ];
   my $atom_opt = opt_atom($first_atom);
   my $rept_opt = opt_rept($next_atom->[1]);
   my $look_opt = opt_atom($look_atom);
   return ['look', [$atom_opt, $rept_opt, $look_opt]];
}

sub opt_alias {
  my $ast = shift;
  my $alias_name = $ast->[0][1];
  my $alias_atom = opt_atom($ast->[1]);
  return ['alias', [$alias_name, $alias_atom]];
}

sub opt_strs {
  my $ast = shift;
  my $str_list = [];
  foreach my $node (values $ast) {
    if ( $node->[0] eq 'str' ) {
      push $str_list, $node->[1];
    }
  }
  return ['strs', $str_list];
}

sub opt_rept {
   my $str = shift;
   given ($str) {
     when ('?')  { [ 0,  1, $str ] }
     when ('*')  { [ 0, -1, $str ] }
     when ('+')  { [ 1, -1, $str ] }
     when ('*?') { [ 0, -1, $str ] }
     when ('+?') { [ 1, -1, $str ] }
     default { error("Unkown Rept value: $str") }
   }
}

sub opt_chclass {
  my $ast = shift;
  my $atoms = [];
  for my $node (values $ast) {
    push $atoms, opt_chclass_node($node);
  }
  return ['chclass', $atoms];
}

sub opt_chclass_node {
  my $node = shift;
  my ($type, $value) = @{ $node };
  given ($type) {
    when ('flip')   { return ['flip', 1] }
    when ('cchar')  { return ['char', $value] }
    when ('char')   { return ['char', $value] }
    when ('cclass') { return ['cclass', $value] }
    when ('range')  { return ['range', $value] }
    default { error("Unknown char class node: $type") }
  }
}

=head1 AUTHOR

Michael Song, C<< <10435916 at qq.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-spp at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Spp>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Spp::Optimizer

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Spp>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Spp>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Spp>

=item * Search CPAN

L<http://search.cpan.org/dist/Spp/>

=back

=head1 ACKNOWLEDGEMENTS

=head1 LICENSE AND COPYRIGHT

Copyright 2015 Michael Song.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1; # End of Spp::Optimizer
