
module my_mod ( port1, port2, port3 );

input port1;
output port3;
inout port_other;


my_mod inst_name 
	(
	.portnormal(just_a_port),
	.portbus(port_with_bus_specifier[7:0]),
	.porttied_high(1'b1), 
	.port1( {connector1,signal2} ), 
	.port2( { 1'b1, other_signal, bussed_signal[3:1]} ) 
	);

endmodule



