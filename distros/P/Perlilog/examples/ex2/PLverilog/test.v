// This is a generated file. Do not edit -- changes will be lost
// Created by Perlilog v0.3 on Tue Nov 11 19:42:08 2003
// Originating object: Template Verilog Obj. 'test'

`timescale 1ns / 10ps

module test(din, ack, clk, rst, cyc, stb, we, adr, dout);

  input [7:0] din;
  input  ack;
  input  clk;
  input  rst;
  output  cyc;
  output  stb;
  output  we;
  output [7:0] adr;
  output [7:0] dout;
  reg  cyc;
  reg  stb;
  reg  we;
  reg [7:0] adr;
  reg [7:0] dout;
  reg [7:0] q;

   integer 	i;

   initial
      begin
	 // initial values	 
	 adr  = 8'hxx;
	 dout = 8'hxx;
	 cyc  = 1'b0;
	 stb  = 1'bx;
	 we   = 1'hx;

	 @(posedge rst); // Wait for reset to go up	 
	 @(negedge rst); // Wait for reset to go down
	 
	 for (i=0; i<8; i=i+1)
	    wb_read(1, i, q);
	 
	 $stop;
      end
   
   ////////////////////////////////////////////////////////////////////
   //
   // Wishbone read cycle
   //
   
   task wb_read;
      input        delay;
      integer 	   delay;
      
      input [7:0] a;
      output [ 7:0] d;
      
      begin
	 repeat(delay) @(posedge clk);
	 #1;
	 adr  = a;
	 dout = 8'hxx;
	 cyc  = 1'b1;
	 stb  = 1'b1;
	 we   = 1'b0;
	 
	 @(posedge clk);
	 while(~ack)	@(posedge clk);
	 #1;
	 cyc  = 1'b0;
	 stb  = 1'bx;
	 adr  = 8'hxx;
	 dout = 8'hxx;
	 we   = 1'hx;
	 d    = din;

	 $display ("Read %d at address %d", d, a);
      end
   endtask

endmodule
