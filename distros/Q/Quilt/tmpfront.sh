#! /bin/perl

$specs_dir = '/home/ken/src/Quilt/specs';


use Getopt::Long;
use SGML::SPGroveBuilder;
use SGML::Grove;
use Quilt;
use Quilt::Writer::Ascii;
use Quilt::Writer::HTML;
use Quilt::XRef;
use Quilt::TOC;

use SGML::Simple::SpecBuilder;
use SGML::Simple::BuilderBuilder;

$| = 1;

$usage = "aack! don't grok!\n";
die "$usage" if !GetOptions("--html"         => \$to_html,
			    "--ascii"        => \$to_ascii,
			    "--sgml"         => \$to_sgml,
			    "--linuxdoc"     => \$linuxdoc,
			    "--docbook"      => \$docbook,
			    "--teilite"      => \$teilite,
			    "--debug"        => sub { $debug ++ },
			    "--help"         => \&help,
			    "--version"      => \&version);

$debug && do {$time = localtime; warn "$time  -- loaded\n"};

my $doc_builder;
$linuxdoc && do {$doc_builder = spec_builder("$specs_dir/linuxdoc.spec")};
$docbook  && do {$doc_builder = spec_builder("$specs_dir/docbook.spec")};
$teilite  && do {$doc_builder = spec_builder("$specs_dir/teilite.spec")};
if ($to_ascii) {
    $to_ascii_builder = spec_builder("$specs_dir/toAscii.spec");
    $wr_ascii_builder = spec_builder("$specs_dir/wrAscii.spec");
}
if ($to_html) {
    $to_html_builder = spec_builder("$specs_dir/toHTML.spec");
    $wr_html_builder = spec_builder("$specs_dir/wrHTML.spec");
    # XXX ooh, this is a hack
    my $ref = ref ($wr_html_builder->new);
    eval "use SGML::Writer";
    eval <<EOF;
{
  package WR_HTML;
  use vars qw{\@ISA};
  \@ISA = qw{$ref SGML::Writer};
  sub new { shift; &SGML::Writer::new ('WR_HTML', @_)}
}
EOF
    $wr_html_builder = bless {}, 'WR_HTML';
}

my $base_name = $ARGV[0];
$base_name =~ s|.*/||;

if ($to_sgml) {
    my $doc = SGML::SPGroveBuilder->new ($ARGV[0]);
    $debug && do {$time = localtime; warn "$time  -- $base_name - loaded\n"};
    my $errors = $doc->errors;
    warn ("errors parsing $ARGV[0]\n" . join ("", @$errors))
	if ($#$errors != -1);
    eval "use SGML::Writer";
    $to_sgml_writer = SGML::Writer->new;
    $doc->accept ($to_sgml_writer);
    exit (0);
}

my $doc_builder_inst = $doc_builder->new;
my $doc_ot = load_doc ($ARGV[0], $doc_builder_inst);

my $context = {};
my $xref_builder = Quilt::XRef->new;
$doc_ot->iter->accept ($xref_builder, $context);
$debug && do {$time = localtime; warn "$time  -- $base_name - build xrefs\n"};

if ($to_ascii) {
    $fot = Quilt::Flow->new();
    $fot_b = $to_ascii_builder->new;
    # XXX hack
    $fot_b->{references} = $context->{references};
    $doc_ot->iter->accept ($fot_b, $fot, {});
    $debug && do {$time = localtime; warn "$time  -- $base_name - build fot\n"};
    $out_b = $wr_ascii_builder->new;
    $fot->iter->accept ($out_b, Quilt::Writer::Ascii->new, {});
}
if ($to_html) {
    $fot = Quilt::Flow->new();
    $fot_b = $to_html_builder->new;
    # XXX hack
    $fot_b->{references} = $context->{references};
    $doc_ot->iter->accept ($fot_b, $fot, {});
    $debug && do {$time = localtime; warn "$time  -- $base_name - build fot\n"};
    $out_b = $wr_html_builder->new;
    $fot->iter->accept ($out_b, Quilt::Writer::HTML->new, {});
}

exit (0);

sub spec_builder {
    my $spec_file = shift;

    my $base_name = $spec_file;
    $base_name =~ s|.*/||;

    my $spec_grove = SGML::SPGroveBuilder->new ("$spec_file");
    $debug && do {my $time = localtime; warn "$time  -- $base_name - loaded\n"};
    my $errors = $spec_grove->errors;
    die ("errors parsing $ARGV[0]\n" . join ("", @$errors))
	if ($#$errors != -1);
    my $spec = SGML::Simple::Spec->new;
    $spec_grove->accept (SGML::Simple::SpecBuilder->new, $spec);
    $debug && do {$time = localtime; warn "$time  -- $base_name - build spec\n"};
    my $builder = SGML::Simple::BuilderBuilder->new (spec => $spec);
    $debug && do {$time = localtime; warn "$time  -- $base_name - build builder\n"};

    return ($builder);
}

sub load_doc {
    my $doc = shift;
    my $builder = shift;

    my $base_name = $doc;
    $base_name =~ s|.*/||;

    my $grove = SGML::SPGroveBuilder->new ($doc);
    $debug && do {$time = localtime; warn "$time  -- $base_name - loaded\n"};
    my $errors = $grove->errors;
    warn ("errors parsing $ARGV[0]\n" . join ("", @$errors))
	if ($#$errors != -1);
    my $ot = Quilt::Flow->new();
    $grove->accept ($builder, $ot->iter, {});
    $debug && do {$time = localtime; warn "$time  -- $base_name - build ot\n"};

    return $ot;
}

# XXX awaiting SPGrove classes using Class::Visitor
package SGML::Element;

package SGML::SData;

package SGML::PI;

package Class::Iter;

sub children_accept_ports {
    my $self = shift;
    my $delegate = $self->delegate;

    # ` "$delegate" =~ /=HASH\(/ ' checks to see if a blessed
    # reference is a hash thanks to the way Perl formats references in
    # string context.  An unblessed hash won't match (no `=').
    # Derived from Data::Dumper
    # XXX in 5.004 we can use `isa()'
    if ("$delegate" =~ /=HASH\(/) {
	my $key;
	foreach $key (keys %$delegate) {
	    if (ref ($delegate->{$key}) eq 'ARRAY') {
		my $method = "children_accept_$key";
		eval {$self->$method (@_)};
	    }
	}
    }
}
