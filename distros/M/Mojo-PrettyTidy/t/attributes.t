use v5.40.0;
use common::sense;
use feature 'signatures';

use Test::More;
use lib 'lib';
use Mojo::PrettyTidy;

sub tidy_attr ( $input ) {
  return
      Mojo::PrettyTidy->new(
                             attributes => 1,
                             columns    => 0,
                             javascript => 0,
                             perl       => 0,
  )->tidy( $input );
}

subtest 'solo media attributes: picture/img' => sub {
  my $input =
q{<picture><img src="<%= url_for_file '/mojo/logo-white.png' %>" srcset="<%= url_for_file '/mojo/logo-white-2x.png' %> 2x"></picture>};

  my $expected = <<'HTML';
<picture>
  <img src="<%= url_for_file '/mojo/logo-white.png' %>"
      srcset="<%= url_for_file '/mojo/logo-white-2x.png' %> 2x">
</picture>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'img attrs format and picture closes align';
};

subtest 'paired anchor with nested picture payload' => sub {
  my $input =
q{<a href="https://mojolicious.org" id="mojobar-brand" class="navbar-brand"><picture><img src="x" srcset="y 2x"></picture></a>};

  my $expected = <<'HTML';
<a href="https://mojolicious.org"
    id="mojobar-brand"
    class="navbar-brand">
  <picture>
    <img src="x"
        srcset="y 2x">
  </picture>
</a>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'anchor attrs format while nested payload remains structured';
};

subtest 'option attributes with EP selected expression' => sub {
  my $input =
q{<select name="mode" onchange="this.form.submit()"><option value="scroll" <%= $mode eq 'scroll' ? 'selected' : '' %>>scroll</option></select>};

  my $expected = <<'HTML';
<select name="mode"
    onchange="this.form.submit()">
  <option value="scroll"
    <%= $mode eq 'scroll' ? 'selected' : '' %>>scroll
  </option>
</select>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'option EP expression is kept whole and split from value attr';
};

subtest 'quoted attribute values containing tags are shielded' => sub {
  my $input =
q{<tr data-bs-toggle="tooltip" data-bs-placement="left" data-bs-html="true" data-bs-title="<b>Regex:</b><code><%= $regex %></code>"><td><span>x</span></td></tr>};

  my $expected = <<'HTML';
<tr data-bs-toggle="tooltip"
    data-bs-placement="left"
    data-bs-html="true"
    data-bs-title="<b>Regex:</b><code><%= $regex %></code>">
<td>
  <span>x</span>
</td>
</tr>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'tags inside quoted attribute values are not split';
};

subtest 'svg and path attributes' => sub {
  my $input =
q{<i class="far fa-copyright"><svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512"><path fill="currentColor" d="M1 2"/></svg></i>};

  my $expected = <<'HTML';
<i class="far fa-copyright">
  <svg xmlns="http://www.w3.org/2000/svg"
      viewBox="0 0 512 512">
    <path fill="currentColor"
        d="M1 2"
        />
  </svg>
</i>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'svg container and path solo attributes format';
};

subtest 'button attributes with nested span payload' => sub {
  my $input =
q{<button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navbarNav" aria-controls="navbarNav"aria-expanded="false" aria-label="Toggle navigation"><span class="navbar-toggler-icon"></span></button>};

  my $expected = <<'HTML';
<button class="navbar-toggler"
    type="button"
    data-bs-toggle="collapse"
    data-bs-target="#navbarNav"
    aria-controls="navbarNav"
    aria-expanded="false"
    aria-label="Toggle navigation">
  <span class="navbar-toggler-icon"></span>
</button>
HTML

  chomp $expected;
  is tidy_attr( $input ), $expected,
      'button attrs format and glued aria attributes are repaired';
};

done_testing;
