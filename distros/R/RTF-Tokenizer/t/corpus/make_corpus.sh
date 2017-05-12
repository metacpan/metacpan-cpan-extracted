find t/9*.t | cut -d'/' -f2 | cut -d'.' -f1 | while IFS= read -r pathname; do
    base=$(basename "$pathname"); name=${base%.*}; ext=${base##*.}
    mv "$pathname" "foo/${name}.bar.${ext}"
done
