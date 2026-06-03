i386-pc-mbr-gpt.img: i386-pc-mbr-gpt.o i386-pc-mbr-gpt.ld
	ld -m elf_i386 -T i386-pc-mbr-gpt.ld i386-pc-mbr-gpt.o -o $@
	truncate -s 512 $@

%.o: %.S
	as --32 $< -o $@

i386-pc-mock-kernel.img: i386-pc-mock-kernel.o i386-pc-mock-kernel.ld
	ld -m elf_i386 -T i386-pc-mock-kernel.ld i386-pc-mock-kernel.o -o $@

check: i386-pc-mbr-gpt.img i386-pc-mock-kernel.img
	rm -f gpt-disk.img
	perl -I ../../lib build-test-img.pl --mbr=i386-pc-mbr-gpt.img --grub=i386-pc-mock-kernel.img -o gpt-disk.img
	qemu-system-x86_64 -drive file=gpt-disk.img,format=raw

.PHONY: check
