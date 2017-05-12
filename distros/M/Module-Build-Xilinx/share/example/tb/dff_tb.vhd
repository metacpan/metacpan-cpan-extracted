--- COPYRIGHT: Selective Intellect LLC
--- AUTHOR: Vikas Kumar
--- DATE: 9th April 2013
--- SOFTWARE: Pong P Chu's examples. Chapter 4

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity testbench is
end testbench;

architecture behavior of testbench is
    constant CLK_PERIOD: time := 20 ns;
    signal clk, reset: std_logic;
    signal d_r, q_r: std_logic; -- to test d_ff_reset
begin
    -- instantiate the D Flip-flop without async reset
    uut2: entity work.d_ff_reset(behavior)
        port map (rst => reset, clk => clk, d => d_r, q => q_r);
    -- we use a 50 MHz clock source which corresponds to 20 ns
    process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process;
    -- set the reset to be 0 after wait time. this is for initialization
    reset <= '1', '0' after CLK_PERIOD / 2;
    -- other data movement
    process
    begin
        -- initialize
        d_r <= '0';
        wait until falling_edge(clk);
        d_r <= '1';
        wait until falling_edge(clk);
        -- run through 10 clock cycles
        for i in 0 to 10 loop
            wait until falling_edge(clk);
        end loop;
        d_r <= '0';
        assert false
            report "Simulation complete"
            severity failure;
    end process;
end behavior;
