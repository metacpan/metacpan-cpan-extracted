package Spreadsheet::Compare::Reporter::HTML;

# TODO: (issue) better JAvascript  event handler
# TODO: (issue) optional read templates/css from files

use Mojo::Base 'Spreadsheet::Compare::Reporter', -signatures;
use Spreadsheet::Compare::Common;
use Mojo::Template;

has sheet_order => sub { [qw(Differences Missing Additional Duplicates All)] };

my %format_defaults = (
    fmt_head       => 'font-weight: bold; text-align: left;',
    fmt_headerr    => 'background-color: yellow',
    fmt_default    => 'color: black;',
    fmt_left_odd   => 'color: blue;',
    fmt_right_odd  => 'color: red;',
    fmt_diff_odd   => 'color: green;',
    fmt_left_even  => 'color: blue;  background-color: silver;',
    fmt_right_even => 'color: red;   background-color: silver;',
    fmt_diff_even  => 'color: green; background-color: silver;',
    fmt_left_high  => 'background-color: yellow;',
    fmt_right_high => 'background-color: yellow;',
    fmt_diff_high  => 'background-color: yellow;',
    fmt_left_low   => 'background-color: lime;',
    fmt_right_low  => 'background-color: lime;',
    fmt_diff_low   => 'background-color: lime;',
);

has $_, $format_defaults{$_} for keys %format_defaults;

has report_filename => sub {
    ( my $title = $_[0]->test_title ) =~ s/[^\w-]/_/g;
    return "$title.html";
};


sub init ($self) {
    my $css_txt = $self->css;
    $css_txt .= ".$_ { " . $self->$_() . "}\n\n" for keys %format_defaults;
    $self->css($css_txt);
    return $self;
}


sub add_stream ( $self, $name ) {
    $self->{ws}{$name} = {};
    return $self;
}


sub _get_fmt ( $self, $name, $side ) {
    $self->{$name}{odd} ^= 1
        if $name eq 'Additional' and $side eq 'right'
        or $side eq 'left';

    my $oe = $self->{$name}{odd} ? 'odd' : 'even';

    return ( "fmt_${side}_$oe", "fmt_${side}_high", "fmt_${side}_low" );
}


sub write_row ( $self, $name, $robj ) {

    my($fnorm) = $self->_get_fmt( $name, $robj->side );

    my $rref = $self->{ws}{$name}{rows} //= [];
    INFO "write_row called\n";
    push @$rref, {
        data    => $self->output_record($robj),
        row_fmt => $fnorm,
        };

    return $self;
}


sub write_fmt_row ( $self, $name, $robj ) {
    my $data = $self->output_record($robj);
    my $mask = $self->strip_ignore( $robj->limit_mask );
    my $off  = $self->head_offset;

    my( $fnorm, $fhigh, $flow ) = $self->_get_fmt( $name, $robj->side );

    my @fmts = map { $fnorm } 1 .. $off;
    push @fmts, map { $_ ? ( $_ == 1 ? $fhigh : $flow ) : '' } @$mask;

    my $rref = $self->{ws}{$name}{rows} //= [];
    push @$rref, {
        data     => $data,
        row_fmt  => $fnorm,
        cell_fmt => \@fmts,
        };

    return $self;
}


sub write_header ( $self, $name ) {
    $self->{ws}{$name}{header} = {
        data    => $self->header,
        row_fmt => "fmt_head",
    };
    return $self;
}


sub mark_header ( $self, $name, $mask ) {
    my $smask = $self->strip_ignore($mask);
    my $off   = $self->head_offset;
    my @fmts  = map { '' } 1 .. $off;
    push @fmts, map { $_ ? 'fmt_headerr' : '' } @$smask;
    $self->{ws}{$name}{header}{cell_fmt} = \@fmts;
    return $self;
}


sub write_summary ( $self, $summary, $filename ) {

    $filename .= '.html' unless $filename =~ /\.html$/i;
    my $pout = $self->report_fullname($filename);
    ( $self->{title} = $pout->basename ) =~ s/\.[^\.]*$//;
    INFO "saving HTML summary to '$pout'";

    $self->{summary} = $summary;
    $self->{header}  = $self->stat_head;

    my $mt   = Mojo::Template->new( vars => 1 );
    my $tmpl = $self->summary_template;

    TRACE "Template:\n$tmpl";
    my $res = $mt->render( $tmpl, $self );
    LOGDIE "Failed to render HTML template: $res" if ref($res) eq 'Mojo::Exception';

    $pout->parent->mkpath;
    $pout->spew($res);

    return $self;
}


sub _fill_html_template ($self) {
    my @sheets = grep { $self->{ws}{$_} } @{ $self->sheet_order() };

    $self->{sheet_names} = \@sheets;
    $self->{active}      = 'Differences';

    my $mt   = Mojo::Template->new( vars => 1 );
    my $tmpl = $self->sheet_template;

    TRACE "Template:\n$tmpl";
    my $res = $mt->render( $tmpl, $self );
    LOGDIE "Failed to render HTML template: $res" if ref($res) eq 'Mojo::Exception';
    return $res;
}


sub save_and_close ($self) {

    my $pout = $self->report_fullname;
    INFO "saving HTML report to '$pout'";
    ( $self->{title} = $pout->basename ) =~ s/\.[^\.]*$//;

    $pout->parent->mkpath;
    $pout->spew( $self->_fill_html_template );

    return $self;
}


has sheet_template => <<'MOJO';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title><%= $title %></title>

    <style><%= $css %></style>

      <script>

        let in_scroll_timer;
        let batch_size = 20;

        document.addEventListener('DOMContentLoaded', function () {
            let active_top  = document.getElementById('top-' + '<%= $active %>');
            window.addEventListener('message', function (ev) {
                if (ev.data === 'toggle') timed_scroll();
            });
            window.addEventListener('resize', timed_scroll);
            window.addEventListener('scroll', timed_scroll);
            toggle_tab(active_top);
        });

        function timed_scroll () {
            if ( in_scroll_timer ) return;
            in_scroll_timer = setTimeout(function () {
                in_scroll_timer = undefined;
                load_rows();
            }, 250);
        }

        function toggle_tab (li) {
            for (let el of document.querySelectorAll(".topbar-item") ) {
                li === el ? el.classList.add('active') : el.classList.remove('active');
            }
            for (let el of document.querySelectorAll(".sheet") ) {
                li.id === 'top-' + el.id ? el.classList.add('active') : el.classList.remove('active');
            }
            timed_scroll();
        }

        function is_visible (el) {
            let rect = el.getBoundingClientRect();
            return ( rect.top >= 0 && rect.top <= window.innerHeight );
        }

        function load_rows () {
            let sheet = document.querySelector(".sheet.active");
            let row = document.querySelector("#" + sheet.id + " .lastrow");
            if (!row) return;
            if (!is_visible(row)) return;
            let rcount = 0;
            let rsize = row.clientHeight ? window.innerHeight / row.clientHeight : batch_size;
            do {
                let next = row.nextElementSibling;
                if (!next) break;
                rcount++;
                row.classList.remove("lastrow");
                row = next;
                row.classList.add("visible");
            } while ( rcount <= rsize );
            row.classList.add("lastrow");
        }

      </script>

  </head>

  <body class="single-sheet" id="sheet-body">

    <div class="topbar" id="div-topbar">
      <ul class="test">
        <% for my $sheet ( @$sheet_names ) { =%>
          <li class="topbar-item" id="top-<%= $sheet %>" onclick="toggle_tab(this)"><a href="#"><%= $sheet %></a></li>
        <% } =%>
      </ul>
    </div> <!-- topbar -->

    <% for my $sheet ( @$sheet_names ) { =%>
      <div class="sheet" id="<%= $sheet %>">
        <table>
          <thead>
            <% my $hdr     = $ws->{$sheet}{header}; =%>
            <% my @htxt    = $hdr->{data}->@*; =%>
            <% my $trclass = $hdr->{row_fmt} // ''; =%>

            <tr class="header-row <%= $trclass %>">
              <% for my $i ( 0 .. $#htxt ) { =%>
                <% my $thclass = $hdr->{cell_fmt} ? $hdr->{cell_fmt}[$i] // '': ''; =%>
                <th class="<%= $thclass %>"><%= $htxt[$i] // '' %></th>
              <% } =%>
            </tr>
          </thead>
          <tbody>
            <% my $rows = $ws->{$sheet}{rows}; =%>
            <% my $rowcount = 0; =%>
            <% for my $r ( @$rows ) { =%>
              <% my $trclass = $r->{row_fmt} // ''; =%>
              <% $trclass .= ' visible lastrow' unless $rowcount++; =%>
              <% my @rtxt    = $r->{data}->@*; =%>
              <tr class="<%= $trclass %>">
                <% for my $i ( 0 .. $#rtxt ) { =%>
                  <% my $tdclass = $r->{cell_fmt} ? $r->{cell_fmt}[$i] // '': ''; =%>
                  <td class="<%= $tdclass %>"><%= $rtxt[$i] // ''%></td>
                <% } =%>
              </tr>
            <% } =%>
          </tbody>
        </table>
      </div> <!-- sheet -->
    <% } =%>

  </body>
</html>
MOJO


has css => <<'CSS';
html {
  margin: 0;
  padding: 0;
  height: 100%;
  font-family: sans-serif;
  font-size: medium;
}

body {
  margin: 0;
  padding: 0;
  /* overflow: hidden; */
  display: flex;
  height: 100%;
  line-height: inherit;  background-color: gray;
}

body.single-sheet {
  flex-direction: column;
}

body.summary {
  flex-direction: row;
}

.topbar ul {
  list-style: none;
  width: 100%;
  margin-block-start: 0.5rem;
  margin-block-end: unset;
  padding-inline-start: .5rem;
}

.topbar li {
  padding: .5rem .5rem .5rem;
  display: inline-block;
  width: 5rem;
  text-align: center;
  border-style: solid;
  border-color: gray;
  border-width: 1px 1px 0 1px;
  border-radius: .5rem .5rem 0 0;
  background-color: silver;
}

.topbar li.active {
  background-color: white;
}

.topbar li:hover {
  text-decoration: none;
  background-color: white;
}

.sidebar {
  display: flex;
  order: -1;
  flex: 0 0 20rem;
  height: 100%;
  overflow: auto;
  background-color: #262626;
}

.sidebar ul {
  list-style: none;
  width: 100%;
  margin-block-start: .3rem;
  margin-block-end: unset;
  padding-inline-start: .3rem;
}

.sidebar li {
  padding-left: .3rem;
  padding-top: .5rem;
  padding-bottom: .5rem;
  display: block;
  text-align: left;
}

.sidebar li.active {
  background-color: #404040;
}

.sidebar li:hover {
  text-decoration: none;
  background-color: #404040;
}

li.sidebar-test-item {
  padding-left: 1rem;
}

.suite-table, .test-iframe {
  flex: 1;
  overflow: auto;
}

a {
  color: black;
  text-decoration: none;
}

.sidebar li a {
  color: #bfbfbf;
}

.sheet {
  display: block;
  visibility: hidden;
  opacity: 0;
  transition: visibility 0s, opacity 0.1s linear;
  position: absolute;
}

.suite-table, .test-iframe {
  display: none;
}

.sheet.active {
  opacity: 1;
  visibility: visible;
  position: static;
}

.suite-table.active, .test-iframe.active {
  display: flex;
}

.suite-table th.left {
  text-align: left;
}

table {
  background-color: white;
}

table, th, td {
  border-collapse:collapse;
}


tr {
  display: none;
}

tr.visible, .suite-row, .header-row, .suite-header {
  display: table-row;
}

th, td {
  border:thin solid black;
  padding:5px;
  white-space: nowrap;
  text-align: left;
}

th {
  position: sticky;
  top: 0;
  background-color: white;
}
CSS


has summary_template => <<'MOJO';
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta name="viewport" content="width=device-width, initial-scale=1">

    <title><%= $title %></title>

    <style><%= $css %></style>

      <script>

        function toggle_test (ev, li) {
            ev.stopPropagation();
            for (let el of document.querySelectorAll(".sidebar-item") ) {
                el.classList.remove('active');
            }
            for (let el of document.querySelectorAll(".suite-table, .test-iframe") ) {
                if (li.id === 'side-' + el.id ) {
                    el.classList.add('active');
                    if ( el.classList.contains("test-iframe") ) {
                        el.contentWindow.postMessage('toggle', '*');
                    }
                } else {
                  el.classList.remove('active');
                }
            }
            li.classList.add('active');
        }

      </script>

  </head>

  <body class="summary">

    <div class="sidebar" id="div-sidebar">
      <ul class="suite">
        <% my $i = 0; =%>
        <% for my $suite ( sort keys %$summary ) { =%>
          <% my $active = $i++ ? '' : 'active'; =%>
          <li class="sidebar-item sidebar-suite-item <%= $active %>" id="side-<%= $suite %>" onclick="toggle_test(event, this)"><a href="#"><%= $suite %></a></li>
          <% for my $test ( $summary->{$suite}->@* ) { =%>
          <li class="sidebar-item sidebar-test-item" id="side-<%= $test->{full} %>" onclick="toggle_test(event, this)"><a href="#"><%= $test->{title} %></a></li>
          <% } =%>
        <% } =%>
      </ul>
    </div> <!-- sidebar -->

    <% $i = 0; =%>
    <% for my $suite ( sort keys %$summary ) { =%>
      <% my $active = $i++ ? '' : 'active'; =%>
      <div class="suite-table <%= $active %>" id="<%= $suite %>">
        <table>
          <thead>
            <tr class="suite-header">
              <% for my $htxt ( @$header ) { =%>
                <% next if $htxt eq 'link'; =%>
                <th><%= $htxt =%></th>
              <% } =%>
            </tr>
          </thead>
          <tbody>
            <% for my $test ( $summary->{$suite}->@* ) { =%>
              <% my $result = $test->{result}; =%>
              <% $result->{title} = $test->{title}; =%>
              <% my @hdr = grep { $_ ne 'link' } @$header; %>
              <% my $data = [ @$result{@hdr} ]; =%>
              <tr class="suite-row">
                <% for my $dtxt ( @$data ) { =%>
                  <% $dtxt //= ''; =%>
                  <% my $class = $dtxt =~ /^[a-z]/i ? 'left' : 'right'; =%>
                  <th class="<%= $class %>"><%= $dtxt %></th>
                <% } =%>
              </tr>
            <% } =%>
          </tbody>
        </table>
      </div>

      <% for my $test ( $summary->{$suite}->@* ) { =%>
      <iframe class="test-iframe" id="<%= $test->{full} %>" src="<%= $test->{report} %>"></iframe>
      <% } =%>
    <% } =%>

  </body>
</html>
MOJO


1;

=head1 NAME

Spreadsheet::Compare::Reporter::HMTL - HTML Report Adapter for Spreadsheet::Compare

=head1 DESCRIPTION

Handles writing Spreadsheet::Compare reports in HTML format.

=head1 ATTRIBUTES

The format attributes have to be valid css styles

The defaults for the attributes are:

    fmt_head       => 'font-weight: bold; text-align: left;',
    fmt_headerr    => 'background-color: yellow',
    fmt_default    => 'color: black;',
    fmt_left_odd   => 'color: blue;',
    fmt_right_odd  => 'color: red;',
    fmt_diff_odd   => 'color: green;',
    fmt_left_even  => 'color: blue;  background-color: silver;',
    fmt_right_even => 'color: red;   background-color: silver;',
    fmt_diff_even  => 'color: green; background-color: silver;',
    fmt_left_high  => 'background-color: yellow;',
    fmt_right_high => 'background-color: yellow;',
    fmt_diff_high  => 'background-color: yellow;',
    fmt_left_low   => 'background-color: lime;',
    fmt_right_low  => 'background-color: lime;',
    fmt_diff_low   => 'background-color: lime;',

=head2 css

A scalar containing the style sheet used for all HTML output.

=head2 sheet_order

A reference to an array with stream names setting the order of the output worksheet tabs
default is: [qw(Differences Missing Additional Duplicates All)]

=head2 sheet_template

A scalar containing a Mojo::Template for constructing an output worksheet.

=head2 summary_template

A scalar containing a Mojo::Template for constructing the summary page.

=head1 METHODS

see L<Spreadsheet::Compare::Reporter>

=cut
