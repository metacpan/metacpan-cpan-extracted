BUILD=../foil/styles
SRC=./src

SRC_FILES=$(shell find src -name '*.*' | grep -v '/_' | grep -v '.swp' | sed -e 's/src/..\/foil\/styles/' -e 's/\.scss/.css/')

all: $(SRC_FILES)

$(BUILD)/themes:
	mkdir $(BUILD)/themes

$(BUILD)/layout:
	mkdir $(BUILD)/layout

$(BUILD)/j:
	mkdir $(BUILD)/j

$(BUILD)/themes/%.css: $(SRC)/themes/%.scss
	sass --sourcemap=none --style expanded --update $(SRC)/themes:$(BUILD)/themes

$(BUILD)/layout/%.css: $(SRC)/layout/%.scss
	sass --sourcemap=none --style expanded --update $(SRC)/layout:$(BUILD)/layout

$(BUILD)/%:  $(SRC)/%
	cp -p $< $@

$(SRC)/themes/themes.json:
	scripts/themes2json --themedir $(SRC)/themes

.PHONY: dump

dump:
	echo $(SRC_FILES)

