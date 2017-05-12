use Module::Build;

my $build=Module::Build->new(
  module_name => 'SVG::Parser',
  license     => 'perl',
  requires    => { SVG => 2.0, required_parser() }
);
$build->create_build_script;

# SVG::Parser requires either XML::Parser or XML::SAX
sub required_parser {
  my @parser;

  eval { require XML::Parser };
  push @parser,'XML::Parser',0 if $INC{"XML/Parser.pm"}; 
  eval { require XML::SAX };
  push @parser,'XML::SAX',0 if $INC{"XML/SAX.pm"};

  print "------------------------------------------------------\n";
  if (@parser) {
    print STDERR "Found installed XML parsers: ",join("\n",@parser),"\n";
  } else {
    print STDERR "SVG::Parser requires either XML::Parser or XML::SAX.\n";
    print STDERR "No XML parser found, adding XML::SAX to prerequisites.\n";
    @parser=("XML::SAX") unless @parser;
  }
  print "------------------------------------------------------\n";
  return @parser;
}
