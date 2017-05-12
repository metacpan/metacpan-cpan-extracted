sub new {
  my $this = shift;
  my $self = $this->SUPER::new(@_);

  $self->addvar('wb_clk_i', 'wire', 'in');
  $self->addvar('wb_rst_i', 'wire', 'in');
  $self->addvar('wb_adr_i', 'wire', 'in');
  $self->addvar('wb_dat_i', 'wire', 'in');
  $self->addvar('wb_dat_o', 'reg', 'out');
  $self->addvar('wb_we_i', 'wire', 'in');
  $self->addvar('wb_stb_i', 'wire', 'in');
  $self->addvar('wb_cyc_i', 'wire', 'in');
  $self->addvar('wb_ack_o', 'wire', 'out');
  
  my $port = wbs->new(name => $self->suggestname('Wishbone_slave_port'),
		      parent => $self,
		      labels => [ clk_i => 'wb_clk_i',
				  rst_i => 'wb_rst_i',
				  cyc_i => 'wb_cyc_i',
				  stb_i => 'wb_stb_i',
				  we_i => 'wb_we_i',
				  ack_o => 'wb_ack_o',
				  adr_i => 'wb_adr_i',
				  dat_i => 'wb_dat_i',
				  dat_o => 'wb_dat_o' ]
		     );
  $self->const(['user_port_names', 'wbport'], $port);

  wrong("The \'romdata\' property is not defined on ".
	$self->who()."\n")
    unless (defined $self->get('romdata'));
  
  return $self;
}  

sub generate {
  my $self = shift;

  my $code = <<'ENDOFCODE';
   assign wb_ack_o = wb_cyc_i && wb_stb_i; // Always single clock cycles
   
   always @(wb_adr_i)
      case (wb_adr_i)
CASES
        default: wb_dat_o = 0;
      endcase
ENDOFCODE

  my $c = 0;
  my $cases = "";
  my $val = 0;
  foreach ($self->get('romdata')) {
    $val = $_ + 0;
    $cases.="        $c: wb_dat_o = $val;\n";
    $c++;
  }
  chomp $cases;
  $code =~ s/CASES/$cases/;
  $self->append($code);
}
