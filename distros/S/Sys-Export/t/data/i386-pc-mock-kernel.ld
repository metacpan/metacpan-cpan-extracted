OUTPUT_FORMAT("binary")
SECTIONS
{
    . = 0x8000;
    .boot : {
        *(.boot)
    }
}
