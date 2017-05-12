`timescale 1ns / 10ps

module rom1(wb_clk_i, wb_rst_i, wb_we_i, wb_stb_i, wb_cyc_i, wb_adr_i,
  wb_dat_i, wb_dat_o, wb_ack_o);

  input  wb_clk_i;
  input  wb_rst_i;
  input  wb_we_i;
  input  wb_stb_i;
  input  wb_cyc_i;
  input [1:0] wb_adr_i;
  input [7:0] wb_dat_i;
  output [7:0] wb_dat_o;
  output  wb_ack_o;
  reg [7:0] wb_dat_o;

   assign wb_ack_o = wb_cyc_i && wb_stb_i; // Always single clock cycles
   
   always @(wb_adr_i)
      case (wb_adr_i)
	3'd0: wb_dat_o = 8'd69;
	3'd1: wb_dat_o = 8'd108;
	3'd2: wb_dat_o = 8'd105;
	3'd3: wb_dat_o = 8'd10;
	default: wb_dat_o = 8'd0;
      endcase

endmodule
