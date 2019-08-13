package Perl::Critic::Policy::CodeLayout::RequireKRBracing;
use strict;
use warnings;
use parent qw[ Perl::Critic::Policy ];
use Perl::Critic::Utils qw[ :severities  ];
use List::MoreUtils qw[ any ];

use constant PBP_PAGE => 9;

my %affected_conditional = map { $_ => 1 } qw( if while unless until );
my %affected_list_loop   = map { $_ => 1 } qw( for foreach );
my %affected_followup    = map { $_ => 1 } qw( else elsif continue );

sub default_severity { return $SEVERITY_LOW }
sub default_themes   { return qw[ cosmetic pbp ] }
sub applies_to       { return 'PPI::Structure::Block' }

sub violates {
    my ($self, $elem, $doc) = @_;

    my ($keyword, $parens) = _affected_construct($elem);
    return if any { not defined } $keyword, $parens; # no affected construct detected

    my $inter_whitespace = $elem->previous_sibling();
    if (not $inter_whitespace->isa('PPI::Token::Whitespace')) {
        return $self->violation("No whitespace between closing '$keyword' parenthesis and opening brace",
            PBP_PAGE, $elem);
    }

    my $pre_whitespace = $parens->previous_sibling();
    if (not $pre_whitespace->isa('PPI::Token::Whitespace')) {
        return $self->violation("No whitespace before opening '$keyword' parenthesis", PBP_PAGE, $parens);
    }

    if (index($inter_whitespace->content, "\n") != -1) {
        return $self->violation("Opening brace of '$keyword' block is not on the same line", PBP_PAGE, $elem);
    }

    my $next_keyword = $elem->snext_sibling();    # else / elsif / continue
    if (    ref $next_keyword
        and $next_keyword->isa('PPI::Token::Word')
        and $affected_followup{$next_keyword})
    {
        my $follow_whitespace = $elem->next_sibling();

        my $no_whitespace = "No whitespace between closing brace and '$next_keyword'";
        return $self->violation($no_whitespace, PBP_PAGE, $next_keyword)
          if not $follow_whitespace->isa('PPI::Token::Whitespace');

        my $no_newline = "'$next_keyword' is on the same line as closing brace";
        return $self->violation($no_newline, PBP_PAGE, $next_keyword)
          if index($follow_whitespace->content, "\n") == -1;
    }

    return;
}

sub _affected_construct {
    my ($elem) = @_;

    my $parens = $elem->sprevious_sibling();
    return if not ref $parens;

    my $is_conditional = $parens->isa('PPI::Structure::Condition');    # if / while / unless / until
    my $is_list_loop   = $parens->isa('PPI::Structure::List');         # for / foreach
    return if not($is_conditional or $is_list_loop);

    my $keyword = $parens->sprevious_sibling();
    if ($keyword->isa('PPI::Token::Word')) {    # a conditional or foreach without an explicit iterator
        return if $is_conditional and not $affected_conditional{$keyword};
        return if $is_list_loop   and not $affected_list_loop{$keyword};
    }
    elsif ($is_list_loop and $keyword->isa('PPI::Token::Symbol')) {   # foreach with an explicit iterator
        $keyword = $keyword->sprevious_sibling();    # go back to either 'my' or 'for'/'foreach'
        $keyword = $keyword->sprevious_sibling       # go back one more token in case of 'my'
          if $keyword->isa('PPI::Token::Word')
          and $keyword->content eq 'my';

        # Should have found the actual keyword by now
        return if not $keyword->isa('PPI::Token::Word');
        return if not $affected_list_loop{$keyword};
    }
    else {
        return;
    }

    return ($keyword, $parens);
}

1;
__END__
=pod

=head1 NAME

Perl::Critic::Policy::CodeLayout::RequireKRBracing - brace in K&R style

=head1 AFFILIATION

This policy as a part of the L<Perl::Critic::PolicyBundle::SNEZ> distribution.

=head1 DESCRIPTION

The K&R style requires less lines per block than BSD and GNU styles without
sacrificing the recognizability of its boundaries. Place the opening brace
of a block at the end of the construct which controls it, not on a new line.

  # not ok
  foreach my $name (@names)
  {
     print "$name\n";
     sign_up($name);
  }

  # ok
  foreach my $name (@names) {
     print "$name\n";
     sign_up($name);
  }

=head1 CONFIGURATION

This Policy is not configurable except for the standard options.

=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

=cut
