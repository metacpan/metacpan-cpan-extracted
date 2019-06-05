use strict;
use warnings;

use RPi::OLED::SSD1306::128_64 qw(:all);

ssd1306_begin(0x2, 0x3c);

ssd1306_clearDisplay();
ssd1306_fillRect(0, 10, 50, 20, 2);
ssd1306_display();

select(undef, undef, undef, 0.2);

ssd1306_clearDisplay();
ssd1306_drawString("My name is stevieb!");
ssd1306_display();

select(undef, undef, undef, 0.2);

ssd1306_clearDisplay();
ssd1306_setTextSize(1);
ssd1306_drawString("My name is stevieb!");
ssd1306_display();

for (1..10) {

    ssd1306_clearDisplay();
    ssd1306_setTextSize($_);
    ssd1306_drawString("My name is stevieb!");
    ssd1306_display();

    select(undef, undef, undef, 0.1);
}
