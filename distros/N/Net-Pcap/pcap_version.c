#include <stdio.h>
#include <pcap.h>

int main(int argc, char *argv[]) {
    printf("%s\n", pcap_lib_version());
}
