`timescale 1ns / 10ps

module logic(wb_clk_i, wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i,
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
  reg [7:0] data1_reg;
  reg [7:0] data2_reg;
  wire [7:0] data1;
  wire [7:0] data2;
  wire [7:0] out1;
  wire [7:0] out2;

  assign out1 = data1 & data2;
  assign out2 = data1 | data2;
  assign wb_ack_o = wb_cyc_i && wb_stb_i;
  always @(wb_adr_i or data1_reg or data2_reg or out1 or out2)
    case (wb_adr_i)
      0: wb_dat_o = data1_reg;
      1: wb_dat_o = data2_reg;
      2: wb_dat_o = out1;
      3: wb_dat_o = out2;
      default: wb_dat_o = 0;
    endcase

  always @(posedge wb_clk_i or posedge wb_rst_i)
    if (wb_rst_i)
      begin
        data1_reg <= #1 0;
        data2_reg <= #1 0;
      end
    else if (wb_cyc_i && wb_stb_i && wb_we_i)
      case (wb_adr_i)
        0: data1_reg <= #1 wb_dat_i;
        1: data2_reg <= #1 wb_dat_i;
      endcase
  assign data1 = data1_reg;
  assign data2 = data2_reg;

endmodule
