`timescale 1ns / 10ps

module rom2(wb_clk_i, wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i,
  wb_stb_i, wb_cyc_i, wb_ack_o);

  input  wb_clk_i;
  input  wb_rst_i;
  input [1:0] wb_adr_i;
  input [7:0] wb_dat_i;
  input  wb_we_i;
  input  wb_stb_i;
  input  wb_cyc_i;
  output [7:0] wb_dat_o;
  output  wb_ack_o;
  reg [7:0] wb_dat_o;

   assign wb_ack_o = wb_cyc_i && wb_stb_i; // Always single clock cycles
   
   always @(wb_adr_i)
      case (wb_adr_i)
        0: wb_dat_o = 65;
        1: wb_dat_o = 66;
        2: wb_dat_o = 67;
        3: wb_dat_o = 10;
        default: wb_dat_o = 0;
      endcase

endmodule
