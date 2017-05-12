--- COPYRIGHT: Vikas Kumar <vikas@cpan.org>
--- AUTHOR: Vikas Kumar
--- DATE: 9th April 2013
--- SOFTWARE: Pong P Chu's examples. Chapter 4

library ieee;
use ieee.std_logic_1164.all;

-- This is a D Flip-flop with asynchronous reset
entity d_ff_reset is
    port (
        clk: std_logic;
        rst: std_logic;
        d: in std_logic;
        q: out std_logic
    );
end d_ff_reset;


architecture behavior of d_ff_reset is
begin
    -- we use a sensitivity list here
    -- this forces the process to be re-evaluated when clk changes in any form
    -- or when rst is set
    process (clk,rst)
    begin
        if (rst = '1') then
            q <= '0';
        -- if on the rising edge of the clock
        elsif (clk'event and clk = '1') then
            q <= d;
        end if;
    end process;
end behavior;
